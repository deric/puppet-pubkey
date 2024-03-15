# frozen_string_literal: true

require 'spec_helper'

describe 'pubkey' do
  _, os_facts = on_supported_os.first
  context 'with default parameters' do
    let(:facts) { os_facts }

    it { is_expected.to compile.with_all_deps }
  end

  context 'multiple keys with custom dir' do
    let(:facts) { os_facts }
    let :pre_condition do
      <<-PP
        pubkey::ssh { 'johndoe_ed25519':
          type    => 'ed25519',
          comment => 'johndoe_ed25519',
          tags    => ['tag_users'],
        }

        pubkey::ssh { 'johndoe_ed25519-sk':
          type    => 'ed25519-sk',
          comment => 'johndoe_ed25519-sk@foobar',
          tags    => ['tag_users'],
        }
      PP
    end

    exported_keys = '/var/cache/pubkey/exported_keys'
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file(exported_keys).with_ensure('file') }

    it { is_expected.to contain_pubkey__ssh('johndoe_ed25519') }
    it { is_expected.to contain_pubkey__ssh('johndoe_ed25519-sk') }

    it {
      is_expected.to contain_file_line('johndoe:/home/johndoe/.ssh/id_ed25519.pub').with(
        path: exported_keys,
      )
    }

    it {
      is_expected.to contain_file_line('johndoe:/home/johndoe/.ssh/id_ed25519_sk.pub').with(
        path: exported_keys,
      )
    }
  end

  context 'autodetect' do
    let(:facts) { os_facts }
    let :pre_condition do
      <<-PP
        pubkey::ssh { 'joe_ed25519':}
        pubkey::ssh { 'joe_ed25519-sk':}
      PP
    end

    exported_keys = '/var/cache/pubkey/exported_keys'
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file(exported_keys).with_ensure('file') }

    it { is_expected.to contain_pubkey__ssh('joe_ed25519') }
    it { is_expected.to contain_pubkey__ssh('joe_ed25519-sk') }

    it {
      is_expected.to contain_pubkey__keygen('keygen-joe_ed25519')
        .with({
                user: 'joe',
                type: 'ed25519',
              })
    }

    it {
      is_expected.to contain_pubkey__keygen('keygen-joe_ed25519-sk')
        .with({
                user: 'joe',
                type: 'ed25519-sk',
              })
    }

    it {
      is_expected.to contain_exec('pubkey-ssh-keygen-joe_ed25519')
        .with({
                command: "ssh-keygen -t ed25519 -q -N '' -C 'joe_ed25519' -f /home/joe/.ssh/id_ed25519",
              })
    }

    it {
      is_expected.to contain_exec('pubkey-ssh-keygen-joe_ed25519-sk')
        .with({
                command: "ssh-keygen -t ed25519-sk -q -N '' -C 'joe_ed25519-sk' -f /home/joe/.ssh/id_ed25519_sk",
              })
    }

    it {
      is_expected.to contain_file_line('joe:/home/joe/.ssh/id_ed25519.pub')
        .with(
        path: exported_keys,
      )
    }

    it {
      is_expected.to contain_file_line('joe:/home/joe/.ssh/id_ed25519_sk.pub')
        .with(
        path: exported_keys,
      )
    }
  end

  context 'with exported_keys' do
    let(:facts) { os_facts }
    let :pre_condition do
      <<-PP
        pubkey::ssh { 'alice_ed25519':
          tags    => ['tag_users'],
        }
        Ssh_authorized_key <<| tag == 'tag_users' |>>
      PP
    end

    exported_keys = '/var/cache/pubkey/exported_keys'
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_pubkey__ssh('alice_ed25519') }

    it {
      is_expected.to contain_pubkey__keygen('keygen-alice_ed25519')
        .with({
                user: 'alice',
                type: 'ed25519',
              })
    }

    it {
      is_expected.to contain_file_line('alice:/home/alice/.ssh/id_ed25519.pub')
        .with(
        path: exported_keys,
      )
    }

    it {
      expect(exported_resources).to contain_ssh_authorized_key('alice_ed25519@host.test').with(
        type: 'ssh-ed25519',
        key: 'AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGgW3IPS7MrL1t8Bta0cZFzvqR8pZMoyuqIVAEXWwb9fAAAABHNzaDo=',
      )
    }
  end

  context 'without generate' do
    let(:facts) { os_facts }
    let :pre_condition do
      <<-PP
        pubkey::ssh { 'bob_ed25519':
          generate => false,
          tags     => ['users'],
        }
        Ssh_authorized_key <<| tag == 'users' |>>
      PP
    end

    exported_keys = '/var/cache/pubkey/exported_keys'
    it { is_expected.to compile.with_all_deps }

    it { is_expected.to contain_pubkey__ssh('bob_ed25519') }

    it { is_expected.not_to contain_pubkey__keygen('keygen-bot_ed25519') }

    it {
      is_expected.to contain_file_line('bob:/home/bob/.ssh/id_ed25519.pub')
        .with(
        path: exported_keys,
      )
    }

    it {
      expect(exported_resources).not_to contain_ssh_authorized_key('bob_ed25519@host.test').with({ type: '' })
    }
  end
end
