# puppet-pubkey

[![Puppet Forge](http://img.shields.io/puppetforge/v/deric/pubkey.svg)](https://forge.puppet.com/modules/deric/pubkey)
[![Tests](https://github.com/deric/puppet-pubkey/actions/workflows/test.yml/badge.svg)](https://github.com/deric/puppet-pubkey/actions/workflows/test.yml)

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
 - `prefix` custom key file prefix for the ssh key file (default: `id`)
 - `comment` ssh key's comment
 - `size` number of bits for generated ssh key
 - `tags` optional tags added to the exported key
 - `export_key` whether export the generated public key as `ssh_authorized_key` (default: `true`)
 - `path` standard unix path to look for ssh-keygen
 - `hostname` that will be part of exported resource
 - `separator` A character for user and key type auto-detection (default: `_`)


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

## How does this work?

On the first run `ssh-keygen` is executed, if the desired ssh key pair doen't exist yet.

Puppet compiles code remotely, on a puppetserver. Which means that the local files are not available at the compile time. Local files (like public ssh keys) can be accessed from Facter code that is evaluated before applying the Puppet catalog. However Facter doesn't accept any arguments, so we don't know which keys to load before evaluating the Puppet code. An intermediate cache file `/var/cache/pubkey/exported_keys` is used to store location of exported keys. During next run the keys are fetched and exported under `pubkey` fact.

Exported ssh keys are stored as hierarchical fact. See `facter --puppet -y pubkey`

```yaml
pubkey:
  bob_ed25519:
    comment: "bob_ed25519"
    key: "AAAAC3NzaC1lZDI1NTE5AAAAIHBqbh2bZtW2jyX5BnsbAahP3KwGSVKVisggLDqJKnkQ"
    type: ssh-ed25519
```

From Puppet code the key is available via `$fact['pubkey']['bob_ed25519']['key']`.

## Limitations

Two consecutives Puppet runs are required to export the key. During the first run ssh key will be generated, during the second one it will be fetched from disk, exported and available as a fact.

## Dependencies

`ssh-keygen` needs to be installed on the system.

Module dependencies:

  - [puppetlabs/stdlib](https://github.com/puppetlabs/puppetlabs-stdlib)
  - [puppetlabs/sshkeys_core](https://github.com/puppetlabs/puppetlabs-sshkeys_core)

## Acceptance test

Run with specific set:

```
BEAKER_destroy=no BEAKER_setfile=debian10-64 bundle exec rake beaker
```
