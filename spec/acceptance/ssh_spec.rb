# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'pry'

describe 'pubkey::ssh' do
  context 'basic setup' do
    it 'generate ssh key' do
      pp = <<~EOS
        pubkey::ssh { 'root_rsa': }
      EOS

      expect(apply_manifest(pp, {
                              catch_failures: false,
                              debug: false,
                            }).exit_code).to be_zero
    end

    describe file('/root/.ssh') do
      it { is_expected.to be_directory }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe file('/root/.ssh/id_rsa') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe file('/root/.ssh/id_rsa.pub') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.to be_readable.by('group') }
      it { is_expected.to be_readable.by('others') }
    end

    describe command('cat /var/cache/pubkey/exported_keys') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match "root:/root/.ssh/id_rsa.pub\n" }
    end
  end

  context 'user account' do
    it 'generate dsa key' do
      pp = <<~EOS
        user { 'john':
          ensure     => present,
          managehome => true,
        }
        pubkey::ssh { 'john_dsa':
          user    => 'john',
          type    => 'dsa',
          require => User['john']
        }
      EOS

      expect(apply_manifest(pp, {
                              catch_failures: false,
                              debug: false,
                            }).exit_code).to be_zero
    end

    describe user('john') do
      it { is_expected.to exist }
    end

    describe file('/home/john') do
      it { is_expected.to be_directory }
    end

    describe file('/home/john/.ssh/id_dsa') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe file('/home/john/.ssh/id_dsa.pub') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.to be_readable.by('group') }
      it { is_expected.to be_readable.by('others') }
    end

    describe command('cat /var/cache/pubkey/exported_keys') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match "john:/home/john/.ssh/id_dsa.pub\n" }
    end
  end

  context 'secure key' do
    it 'generate ssh key' do
      pp = <<~EOS
        pubkey::ssh { 'john_ed25519-sk': }
      EOS

      expect(apply_manifest(pp, {
                              catch_failures: false,
                              debug: false,
                            }).exit_code).to be_zero

      expect(apply_manifest(pp, {
                              catch_failures: false,
                              debug: false,
                            }).exit_code).to be_zero
    end

    describe file('/home/john/.ssh') do
      it { is_expected.to be_directory }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe file('/home/john/.ssh/id_ed25519_sk') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.not_to be_readable.by('group') }
      it { is_expected.not_to be_readable.by('others') }
    end

    describe file('/home/john/.ssh/id_ed25519_sk.pub') do
      it { is_expected.to be_file }
      it { is_expected.to be_readable.by('owner') }
      it { is_expected.to be_readable.by('group') }
      it { is_expected.to be_readable.by('others') }
    end

    describe command('cat /var/cache/pubkey/exported_keys') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match "john:/home/john/.ssh/id_ed25519_sk.pub\n" }
    end
  end
end
