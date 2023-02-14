# puppet-pubkey

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
 - `export` whether export the generated key (default: `true`)
 - `path` standard unix path to look for ssh-keygen
 - `hostname` that will be part of exported resource


## Advanced configuration

```
pubkey::ssh { 'alice':
  user    => 'alice',
  type    => 'ed25519',
  comment => 'alice_ed25519@foo.bar'
}
```
