# @summary Internal class to validate detected parameters
#
# @api private
define pubkey::keygen (
  String               $user,
  Pubkey::Type         $type,
  Stdlib::AbsolutePath $path,
  Stdlib::UnixPath     $privkey_path,
  String               $comment,
  Optional[Integer]    $size,
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
