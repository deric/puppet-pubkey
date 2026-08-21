# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require_relative '../../../lib/facter/pubkey'

describe 'pubkey fact' do
  cache_file = '/var/cache/pubkey/exported_keys'

  subject(:fact) { Facter.fact(:pubkey).value }

  before(:each) do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
  end

  after(:each) do
    Facter.clear
  end

  context 'without cache file' do
    before(:each) do
      allow(File).to receive(:exist?).with(cache_file).and_return(false)
    end

    it { is_expected.to eq({}) }
  end

  context 'with multiple keys for the same user' do
    first_key = 'AAAAC3NzaC1lZDI1NTE5AAAAIGeVK8hndufeFsIQDgd5tGtLEcYGMjxggHwzCQF+ooUg'
    second_key = 'AAAAC3NzaC1lZDI1NTE5AAAAIKsrFnG8FODegr/4EiAG5NvuLOs7Va+Crv3Gy5WKNoeC'

    before(:each) do
      allow(File).to receive(:exist?).with(cache_file).and_return(true)
      allow(File).to receive(:foreach).with(cache_file)
                                      .and_yield("test1_ed25519:/root/.ssh/test1_ed25519.pub\n")
                                      .and_yield("test2_ed25519:/root/.ssh/test2_ed25519.pub\n")
      allow(File).to receive(:file?).and_return(true)
      allow(IO).to receive(:readlines).with('/root/.ssh/test1_ed25519.pub', chomp: true)
                                      .and_return(["ssh-ed25519 #{first_key} test1_ed25519"])
      allow(IO).to receive(:readlines).with('/root/.ssh/test2_ed25519.pub', chomp: true)
                                      .and_return(["ssh-ed25519 #{second_key} test2_ed25519"])
    end

    it 'keeps an entry per resource title' do
      expect(fact).to eq({
                           'test1_ed25519' => {
                             'type' => 'ssh-ed25519',
                             'key' => first_key,
                             'comment' => 'test1_ed25519',
                           },
                           'test2_ed25519' => {
                             'type' => 'ssh-ed25519',
                             'key' => second_key,
                             'comment' => 'test2_ed25519',
                           },
                         })
    end
  end

  context 'with titles containing spaces and quotes' do
    key = 'AAAAC3NzaC1lZDI1NTE5AAAAIGeVK8hndufeFsIQDgd5tGtLEcYGMjxggHwzCQF+ooUg'

    before(:each) do
      allow(File).to receive(:exist?).with(cache_file).and_return(true)
      allow(File).to receive(:foreach).with(cache_file)
                                      .and_yield("bob's key:/home/bob/.ssh/id_ed25519.pub\n")
      allow(File).to receive(:file?).and_return(true)
      allow(IO).to receive(:readlines).with('/home/bob/.ssh/id_ed25519.pub', chomp: true)
                                      .and_return(["ssh-ed25519 #{key} bob's key"])
    end

    it 'uses the whole title as the fact key' do
      expect(fact.keys).to eq(["bob's key"])
      expect(fact["bob's key"]['key']).to eq(key)
    end
  end

  context 'with a missing public key file' do
    before(:each) do
      allow(File).to receive(:exist?).with(cache_file).and_return(true)
      allow(File).to receive(:foreach).with(cache_file)
                                      .and_yield("john_rsa:/home/john/.ssh/id_rsa.pub\n")
      allow(File).to receive(:file?).with('/home/john/.ssh/id_rsa.pub').and_return(false)
    end

    it { is_expected.to eq({ 'john_rsa' => {} }) }
  end

  describe 'pubkey_parse_ssh_key' do
    key = 'AAAAC3NzaC1lZDI1NTE5AAAAIGeVK8hndufeFsIQDgd5tGtLEcYGMjxggHwzCQF+ooUg'

    it 'parses type, key and comment' do
      expect(pubkey_parse_ssh_key("ssh-ed25519 #{key} bob@example.com")).to eq({
                                                                                 'type' => 'ssh-ed25519',
                                                                                 'key' => key,
                                                                                 'comment' => 'bob@example.com',
                                                                               })
    end

    it 'preserves key options' do
      parsed = pubkey_parse_ssh_key("no-agent-forwarding ssh-ed25519 #{key} backup")
      expect(parsed['type']).to eq('no-agent-forwardingssh-ed25519')
      expect(parsed['key']).to eq(key)
    end

    it 'raises on invalid input' do
      expect { pubkey_parse_ssh_key('garbage') }.to raise_error(ArgumentError, %r{Wrong Keyline format})
    end
  end
end
