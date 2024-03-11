# @summary Common configuration
#
# @param cache_dir
#   Directory to persist data between puppet runs
#
# @example
#   include pubkey
class pubkey (
  Stdlib::UnixPath $cache_dir,
) {
}
