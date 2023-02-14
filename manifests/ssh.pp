# @summary Generate ssh key pair and exports public ssh key
#
# Exports public ssh key to Puppetserver
#
# @param user account name under which we will store the ssh key
# @param type ssh key type one of: 'dsa', 'rsa', 'ecdsa', 'ed25519', 'ecdsa-sk', 'ed25519-sk'
# @param home user's home directory, assuming .ssh is located in $HOME/.ssh
# @param comment ssh key's comment
# @param size number of bits for generated ssh key
# @param tags optional tags added to the exported key
# @param export whether export the generated key (default: true)
# @param path standard unix path to look for ssh-keygen
# @param hostname that will be part of exported resource
#
# @example
#   pubkey::ssh { 'john_rsa': }
define pubkey::ssh (
  Optional[String]           $user = undef,
  Optional[Pubkey::Type]     $type = undef,
  Stdlib::AbsolutePath       $path = $facts['path'],
  Optional[Stdlib::UnixPath] $home = undef,
  Optional[String]           $comment = undef,
  Optional[Integer]          $size = undef,
  String                     $hostname = $facts['networking']['fqdn'],
  Optional[Array[String]]    $tags = undef,
  Boolean                    $export = true,
) {
  # try to auto-detect username and key type
  if empty($type) or empty($user) {
    $array = split($title, '_')
  }

  $_type = $type ? {
    undef   => size($array) > 1 ? { true => $array[1], false => fail('unable to determine type') },
    default => $type
  }

  $_user = $user ? {
    undef   => size($array) >= 1 ? { true => $array[0], false => fail('unable to determine user') },
    default => $user
  }

  $_home = $home ? {
    undef   => "/home/${_user}",
    default => $home,
  }

  $key_bits = $size ? {
    undef   => '',
    default => "-b ${size}"
  }

  $_comment = $comment ? {
    undef   => shellquote($title),
    default => shellquote($comment)
  }

  $privkey_path = pubkey::ssh_key_path("${_home}/.ssh", $_type, false)
  $pubkey_path = pubkey::ssh_key_path("${_home}/.ssh", $_type, true)

  exec { "ssh-keygen-${title}":
    command => "ssh-keygen -t ${_type} -q ${key_bits} -N '' -C '${_comment}' -f ${privkey_path}",
    creates => $privkey_path,
    user    => $_user,
    onlyif  => "test ! -f ${privkey_path}",
    path    => $path,
  }

  if $export {
    file { '/var/cache/pubkey':
      ensure  => directory,
    }

    ini_setting { 'pubkey':
      ensure    => present,
      path      => '/var/cache/pubkey/exported_keys.ini',
      section   => 'ssh_keys',
      setting   => $title,
      value     => $pubkey_path,
      show_diff => true,
      require   => File['/var/cache/pubkey'],
    }

    # Load ssh public key for given local user
    # NOTE: we can't access remote disk from a compile server
    # and exported resources doesn't support Deferred objects
    if 'pubkey' in $facts and $_user in $facts['pubkey'] {
      $ssh_key = $facts['pubkey'][$_user]['key']
      @@ssh_authorized_key { "${title}@${hostname}":
        ensure => present,
        user   => $_user,
        type   => $facts['pubkey'][$_user]['type'],
        key    => $ssh_key,
        tag    => $tags,
      }
    }
  }
}
