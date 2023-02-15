# @summary Internal class to validate detected parameters
#
# @api private
define pubkey::keygen (
  String[1]            $user,
  Pubkey::Type         $type,
  Stdlib::AbsolutePath $path,
  Stdlib::UnixPath     $privkey_path,
  String[1]            $comment,
  Optional[Integer]    $size = undef,
) {
  $key_bits = $size ? {
    undef   => '',
    default => " -b ${size}"
  }

  exec { "pubkey-ssh-${title}":
    command => "ssh-keygen -t ${type} -q${key_bits} -N '' -C '${comment}' -f ${privkey_path}",
    creates => $privkey_path,
    user    => $user,
    onlyif  => "test ! -f ${privkey_path}",
    path    => $path,
  }
}
