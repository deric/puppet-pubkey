# frozen_string_literal: true

# https://github.com/puppetlabs/puppet-specifications/blob/master/language/func-api.md#the-4x-api
Puppet::Functions.create_function(:"pubkey::ssh_key_path") do
  dispatch :ssh_key_path do
    param 'String', :ssh_dir
    param 'String', :ssh_type
    param 'Boolean', :pubkey
    return_type 'String'
  end

  def ssh_key_path(dir, ssh_type = 'ed25519', pubkey = true)
    key = case ssh_type
          when 'dsa'
            'id_dsa'
          when 'rsa'
            'id_rsa'
          when 'ecdsa'
            'id_ecdsa'
          when 'ecdsa-sk'
            'id_ecdsa_sk'
          when 'ed25519'
            'id_ed25519'
          when 'ed25519-sk'
            'id_ed25519_sk'
          end

    path = "#{dir}/#{key}"
    path = "#{path}.pub" if pubkey
    path
  end
end
