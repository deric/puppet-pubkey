# frozen_string_literal: true

require 'spec_helper'

describe 'pubkey::ssh' do
  _, os_facts = on_supported_os.first
  let(:facts) do
    os_facts.merge({ hostname: 'localhost' })
  end

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

    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('present') }

    line = 'bob:/home/bob/.ssh/id_rsa.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t rsa -q -b 4096 -N '' -C '\"bob's key\"' -f /home/bob/.ssh/id_rsa
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-bob\'s key').with_command(cmd.delete("\n"))
      is_expected.to contain_pubkey__keygen('keygen-bob\'s key')
    end

    # The public key can't be loaded on the first run
    it {
      expect(exported_resources).not_to contain_ssh_authorized_key('bob\'s key@localhost').with(
        user: 'bob',
        type: 'ssh-rsa',
      )
    }
  end

  context 'guess username and type from title' do
    let(:title) { 'john_dsa' }

    it { is_expected.to compile }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('present') }

    line = 'john:/home/john/.ssh/id_dsa.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t dsa -q -N '' -C 'john_dsa' -f /home/john/.ssh/id_dsa
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-john_dsa').with_command(cmd.delete("\n"))
      is_expected.to contain_pubkey__keygen('keygen-john_dsa')
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
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('present') }

    line = 'alice:/home/alice/.ssh/id_ed25519.pub'
    it {
      is_expected.not_to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t ed25519 -q -N '' -C 'my_ssh_key' -f /home/alice/.ssh/id_ed25519
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-alice_ed25519').with_command(cmd.delete("\n"))
      is_expected.to contain_pubkey__keygen('keygen-alice_ed25519')
    end
  end

  context 'no type param or in title' do
    let(:title) { 'alice_secret_key' }

    it { is_expected.to raise_error(Puppet::Error, %r{parameter 'type' expects a match for Pubkey::Type}) }
  end

  context 'no username in title' do
    let(:title) { '_rsa' }

    it { is_expected.to raise_error(Puppet::Error, %r{parameter 'user' expects}) }
  end
end
