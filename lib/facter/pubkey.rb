# frozen_string_literal: true

require 'facter'

def pubkey_fetch_key(path)
  return {} unless File.file?(path)
  lines = IO.readlines(path, chomp: true)
  pubkey_parse_ssh_key(lines.join(''))
end

def pubkey_parse_ssh_key(str)
  matched = str.match(%r{((sk-ecdsa-|ssh-|ecdsa-)[^\s]+)\s+([^\s]+)\s+(.*)$})
  raise ArgumentError, "Wrong Keyline format: #{str}" unless matched && matched.length == 5
  key = {
    'type' => matched[1],
    'key' => matched[3],
  }
  options = str[0, str.index(matched[0])].rstrip
  comment = matched[4]
  key['options'] = options unless options.empty?
  key['comment'] = comment unless comment.empty?

  key
end

Facter.add(:pubkey) do
  confine kernel: 'Linux'
  setcode do
    res = {}
    keys = '/var/cache/pubkey/exported_keys'
    if File.exist?(keys)
      regexp = %r{([A-Za-z0-9-]+):(.*)}
      File.foreach(keys) do |line|
        if line.match? regexp
          m = line.match regexp
          res[m[1]] = pubkey_fetch_key(m[2])
        end
      end
    end
    res
  end
end
