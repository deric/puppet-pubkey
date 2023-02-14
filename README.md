# puppet-pubkey

[![Static & Spec Tests](https://github.com/deric/puppet-pubkey/actions/workflows/spec.yml/badge.svg)](https://github.com/deric/puppet-pubkey/actions/workflows/spec.yml)

Puppet module that allows generating ssh key pair and exchanging the public key via exported Puppet resource.

## Usage

As simple as:

```puppet
pubkey::ssh { 'bob_rsa': }
```
will generate `/home/bob/.ssh/id_rsa` key with default size and export the public key `/home/bob/.ssh/id_rsa.pub`.

Auto-detection expects name in format `{username}_{type}`.

## Parameters

 - `user` account name under which we will store the ssh key
 - `type` ssh key type one of: `dsa`, `rsa`, `ecdsa`, `ed25519`, `ecdsa-sk`, `ed25519-sk`
 - `home` user's home directory, assuming .ssh is located in $HOME/.ssh
 - `comment` ssh key's comment
 - `size` number of bits for generated ssh key
 - `tags` optional tags added to the exported key
 - `export` whether export the generated public key as `ssh_authorized_key` (default: `true`)
 - `path` standard unix path to look for ssh-keygen
 - `hostname` that will be part of exported resource


## Advanced configuration

Optionally provide override any parameter
```puppet
pubkey::ssh { 'alice_key':
  user     => 'alice',
  type     => 'ed25519',
  home     => '/home/alice',
  comment  => 'alice_ed25519@foo.bar',
  hostname => 'foo'
  export   => false,
  tags     => ['tag_users', 'bar'],
}
```
The key will be exported as `alice_key@foo`. In order to import the key on other machine use e.g.:

```puppet
Ssh_authorized_key <<| tag == "tag_users" |>>
```

## Limitations

Two consecutives Puppet runs are required to export the key. During the first run ssh key will be generated, during second one exported.

## Dependencies

  - [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
  - [puppetlabs/inifile](https://github.com/puppetlabs/puppetlabs-inifile)
