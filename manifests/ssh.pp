# @summary Generate ssh key pair and exports public ssh key
#
# Exports public ssh key to Puppetserver
#
# @param generate Whether missing key should be generated
# @param user account name where ssh key is (optionally) generated and public key stored into exported resource
# @param target_user account name under which we will store the authorized key (by default same as `user`)
# @param type ssh key type one of: 'dsa', 'rsa', 'ecdsa', 'ed25519', 'ecdsa-sk', 'ed25519-sk'
# @param home user's home directory, assuming .ssh is located in $HOME/.ssh
# @param prefix custom key file prefix for the ssh key file (default: 'id')
# @param comment ssh key's comment
# @param size number of bits for generated ssh key
# @param tags optional tags added to the exported key
# @param export_key whether export the generated key (default: true)
# @param path standard unix path to look for ssh-keygen
# @param hostname that will be part of exported resource
# @param separator A character for user and type auto-detection (default: '_')
#
# @example
#   pubkey::ssh { 'john_rsa': }
#
# @example
#  pubkey::ssh { 'johndoe':
#    type    => 'ed25519',
#    comment => 'johndoe_ed25519',
#    tags    => ['users'],
#  }
#
# @example
#  pubkey::ssh { 'bob_ed25519':
#    user        => 'bob', # auto-detected from title
#    target_user => 'deploy', # user account under which authorized key will be stored
#    tags        => ['users'],
#  }
define pubkey::ssh (
  Boolean                    $generate = true,
  Optional[String[1]]        $user = undef,
  Optional[String[1]]        $target_user = undef,
  Optional[Pubkey::Type]     $type = undef,
  Stdlib::AbsolutePath       $path = $facts['path'],
  Optional[Stdlib::UnixPath] $home = undef,
  Optional[String[1]]        $prefix = undef,
  Optional[String[1]]        $comment = undef,
  Optional[Integer]          $size = undef,
  String                     $hostname = $facts['networking']['fqdn'],
  Optional[Array[String]]    $tags = undef,
  Boolean                    $export_key = true,
  String[1]                  $separator = '_',
) {
  # try to auto-detect username and key type
  if empty($type) or empty($user) {
    $array = split($title, $separator)
  }

  $_type = $type ? {
    undef   => size($array) > 1 ? {
      true => $array[1],
      false => fail('unable to determine type')
    },
    default => $type
  }

  $_user = $user ? {
    undef   => size($array) >= 1 ? {
      true => $array[0],
      false => fail('unable to determine user')
    },
    default => $user
  }

  $_target_user = $target_user ? {
    undef   => $_user,
    default => $target_user,
  }

  $_home = $home ? {
    undef   => $_user ? {
      'root'  => '/root',
      default => "/home/${_user}",
    },
    default => $home,
  }

  $_comment = $comment ? {
    undef   => shellquote($title),
    default => shellquote($comment)
  }

  $_prefix = $prefix ? {
    undef   => 'id',
    default => $prefix,
  }

  # convert e.g. ecdsa-sk to ecdsa_sk
  $key_file = regsubst($_type, '\-','_',)

  $privkey_path = "${_home}/.ssh/${_prefix}_${key_file}"
  $pubkey_path = "${_home}/.ssh/${_prefix}_${key_file}.pub"

  if $generate {
    pubkey::keygen { "keygen-${title}":
      user         => $_user,
      type         => $_type,
      path         => $path,
      privkey_path => $privkey_path,
      comment      => $_comment,
      size         => $size,
    }
  }

  if $export_key {
    include pubkey
    # Hardcoded, needs to be the same in facter code
    $cache_dir = '/var/cache/pubkey'

    file_line { "${_user}:${pubkey_path}":
      path    => "${cache_dir}/exported_keys",
      line    => "${_user}:${pubkey_path}",
      require => [File[$cache_dir], Class['Pubkey']],
    }

    # Load ssh public key for given local user
    # NOTE: we can't access remote disk from a compile server
    # and exported resources doesn't support Deferred objects
    if 'pubkey' in $facts and $_user in $facts['pubkey'] {
      $_key = $facts['pubkey'][$_user]
      if 'type' in $_key and 'key' in $_key {
        if !empty($_key['type']) and !empty($_key['key']) {
          @@ssh_authorized_key { "${title}@${hostname}":
            ensure => present,
            user   => $_target_user,
            type   => $_key['type'],
            key    => $_key['key'],
            tag    => $tags,
          }
        } else {
          warning("ssh_authorized_key type can't be empty: ${_key}")
        }
      }
    }
  }
}
