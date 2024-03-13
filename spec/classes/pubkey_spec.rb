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
end
