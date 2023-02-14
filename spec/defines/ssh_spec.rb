# frozen_string_literal: true

require 'spec_helper'

describe 'pubkey::ssh' do
  _, os_facts = on_supported_os.first
  let(:facts) { os_facts }

  context 'with username and type' do
    let(:title) { 'bob\'s key' }
    let(:params) do
      {
        type: 'rsa',
        user: 'bob',
        size: 4096,
      }
    end

    it { is_expected.to compile }

    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }

    it {
      is_expected.to contain_ini_setting('pubkey').with(
        {
          ensure: 'present', section: 'ssh_keys',
          setting: 'bob\'s key', value: '/home/bob/.ssh/id_rsa.pub',
          path: '/var/cache/pubkey/exported_keys.ini'
        },
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t rsa -q -b 4096 -N '' -C 'bob's key' -f /home/bob/.ssh/id_rsa
      CMD

      is_expected.to contain_exec('ssh-keygen-bob\'s key').with_command(cmd.delete("\n"))
    end
  end

  context 'guess username and type from title' do
    let(:title) { 'john_dsa' }

    it { is_expected.to compile }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }

    it {
      is_expected.to contain_ini_setting('pubkey').with(
        {
          ensure: 'present', section: 'ssh_keys',
          setting: 'john_dsa', value: '/home/john/.ssh/id_dsa.pub',
          path: '/var/cache/pubkey/exported_keys.ini'
        },
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t dsa -q  -N '' -C 'john_dsa' -f /home/john/.ssh/id_dsa
      CMD

      is_expected.to contain_exec('ssh-keygen-john_dsa').with_command(cmd.delete("\n"))
    end
  end

  context 'with custom comment, without export' do
    let(:title) { 'alice_ed25519' }

    let(:params) do
      {
        comment: 'my_ssh_key',
        export: false,
      }
    end

    it { is_expected.to compile }
    it { is_expected.not_to contain_file('/var/cache/pubkey').with_ensure('directory') }

    it {
      is_expected.not_to contain_ini_setting('pubkey').with(
        {
          ensure: 'present', section: 'ssh_keys',
          setting: 'alice_rsa', value: '/home/alice/.ssh/id_ed25519.pub',
          path: '/var/cache/pubkey/exported_keys.ini'
        },
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t ed25519 -q  -N '' -C 'my_ssh_key' -f /home/alice/.ssh/id_ed25519
      CMD

      is_expected.to contain_exec('ssh-keygen-alice_ed25519').with_command(cmd.delete("\n"))
    end
  end
end
