# Changelog

All notable changes to this project will be documented in this file.

## [2023-02-15] Release 0.6.0

**Features**

 - Allow custom separator for splitting user-key type.
 - Support `root` account without overriding `home`
 - Added acceptance tests

**Bugfixes**

 - Added missing `sshkeys_core` dependency
 - `export` might conflict with metaparam (#1)

 [Full changes](https://github.com/deric/puppet-pubkey/compare/v0.5.0...v0.6.0)


## [2023-02-15] Release 0.5.0

**Features**

 - Replace custom function by simple puppet code
 - Support custom key file prefix

**Bugfixes**

 - Fixed ensure on cache file
 - Don't allow passing empty strings

 [Full changes](https://github.com/deric/puppet-pubkey/compare/v0.4.0...v0.5.0)


## [2023-02-15] Release 0.4.0

**Bugfixes**

 - Ensure cache file exists, before adding to it
 - Return empty hash if the public key doesn't exist

 [Full changes](https://github.com/deric/puppet-pubkey/compare/v0.3.0...v0.4.0)


## [2023-02-15] Release 0.3.0

**Bugfixes**

 - Fixed test

 [Full changes](https://github.com/deric/puppet-pubkey/compare/v0.2.0...v0.3.0)


## [2023-02-15] Release 0.2.0

**Features**

 - Removed inifile module dependency

**Bugfixes**

 - Fixed validation of empty username
 - Gracefuly ignore missing ssh key

 [Full changes](https://github.com/deric/puppet-pubkey/compare/v0.1.0...v0.2.0)

## [2023-02-14] Release 0.1.0

**Features**

 - Initial implementation, supports generating and exporting public ssh keys
