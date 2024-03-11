# @summary Common configuration
#
# @param cache_owner
#   Owner of the cache directory
# @param cache_group
#   Group of the cache directory
# @param export_keys
#   Whether manage directory for exported keys. Note in order to disable
#   pubkey::ssh::export_key should be set to `false` on each key.
#
# @example
#   include pubkey
class pubkey (
  String           $cache_owner,
  String           $cache_group,
  Boolean          $export_keys,
) {
  if $export_keys {
    # This is hardcoded because we can't pass arguments to facter
    # TODO: might be modified using a fact?
    $cache_dir = '/var/cache/pubkey'
    ensure_resource('file', $cache_dir, {
        'ensure'  => directory,
        'owner'   => $cache_owner,
        'group'   => $cache_group,
        'mode'    => '0644',
    })

    ensure_resource('file', "${cache_dir}/exported_keys", {
        'ensure'  => file,
        'owner'   => $cache_owner,
        'group'   => $cache_group,
        'require' => File[$cache_dir],
    })
  }
}
