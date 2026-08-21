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
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'bob\'s key:/home/bob/.ssh/id_rsa.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'removes legacy username-keyed cache entry' do
      is_expected.to contain_file_line('bob:/home/bob/.ssh/id_rsa.pub').with(
        ensure: 'absent',
        path: '/var/cache/pubkey/exported_keys',
        line: 'bob:/home/bob/.ssh/id_rsa.pub',
      )
    end

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t rsa -q -b 4096 -N '' -C '\"bob's key\"' -f /home/bob/.ssh/id_rsa
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-bob\'s key')
        .with({
                command: cmd.delete("\n"),
                creates: '/home/bob/.ssh/id_rsa',
              })

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
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'john_dsa:/home/john/.ssh/id_dsa.pub'
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

      is_expected.to contain_exec('pubkey-ssh-keygen-john_dsa')
        .with({
                command: cmd.delete("\n"),
                creates: '/home/john/.ssh/id_dsa',
              })
      is_expected.to contain_pubkey__keygen('keygen-john_dsa')
    end
  end

  context 'with custom comment, without export' do
    let(:title) { 'alice_ed25519' }

    let(:params) do
      {
        comment: 'my_ssh_key',
        export_key: false,
      }
    end

    it { is_expected.to compile }
    it { is_expected.not_to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.not_to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'alice_ed25519:/home/alice/.ssh/id_ed25519.pub'
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

      is_expected.to contain_exec('pubkey-ssh-keygen-alice_ed25519')
        .with({
                command: cmd.delete("\n"),
                creates: '/home/alice/.ssh/id_ed25519',
              })
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

  context 'empty title' do
    let(:title) { '-' }

    it { is_expected.to raise_error(Puppet::Error, %r{unable to determine type}) }
  end

  context 'with ed25519-sk type' do
    let(:title) { 'trudy_ed25519-sk' }

    it { is_expected.to compile }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'trudy_ed25519-sk:/home/trudy/.ssh/id_ed25519_sk.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    # TODO: this might require no-touch-required option to make this useful
    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t ed25519-sk -q -N '' -C 'trudy_ed25519-sk' -f /home/trudy/.ssh/id_ed25519_sk
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-trudy_ed25519-sk')
        .with({
                command: cmd.delete("\n"),
                creates: '/home/trudy/.ssh/id_ed25519_sk',
              })
      is_expected.to contain_pubkey__keygen('keygen-trudy_ed25519-sk')
    end
  end

  context 'with custom key prefix name' do
    let(:title) { 'custom key' }
    let(:params) do
      {
        type: 'rsa',
        user: 'george',
        size: 2048,
        prefix: 'foo',
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'custom key:/home/george/.ssh/foo_rsa.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t rsa -q -b 2048 -N '' -C '\"custom key\"' -f /home/george/.ssh/foo_rsa
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-custom key')
        .with({
                command: cmd.delete("\n"),
                creates: '/home/george/.ssh/foo_rsa',
              })
      is_expected.to contain_pubkey__keygen('keygen-custom key')
    end
  end

  context 'root account' do
    let(:title) { 'root_key' }
    let(:params) do
      {
        type: 'rsa',
        user: 'root',
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'root_key:/root/.ssh/id_rsa.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t rsa -q -N '' -C 'root_key' -f /root/.ssh/id_rsa
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-root_key')
        .with({
                command: cmd.delete("\n"),
                creates: '/root/.ssh/id_rsa',
              })
      is_expected.to contain_pubkey__keygen('keygen-root_key')
    end
  end

  context 'with custom home and separator' do
    let(:title) { 'postgres-rsa' }
    let(:params) do
      {
        home: '/var/lib/postgresql',
        separator: '-',
      }
    end

    it { is_expected.to compile }
    it { is_expected.to contain_file('/var/cache/pubkey').with_ensure('directory') }
    it { is_expected.to contain_file('/var/cache/pubkey/exported_keys').with_ensure('file') }

    line = 'postgres-rsa:/var/lib/postgresql/.ssh/id_rsa.pub'
    it {
      is_expected.to contain_file_line(line).with(
        path: '/var/cache/pubkey/exported_keys',
        line: line,
      )
    }

    it 'generates ssh key pair' do
      cmd = <<~CMD
        ssh-keygen -t rsa -q -N '' -C 'postgres-rsa' -f /var/lib/postgresql/.ssh/id_rsa
      CMD

      is_expected.to contain_exec('pubkey-ssh-keygen-postgres-rsa')
        .with({
                command: cmd.delete("\n"),
                creates: '/var/lib/postgresql/.ssh/id_rsa',
              })
      is_expected.to contain_pubkey__keygen('keygen-postgres-rsa')
    end
  end

  context 'with multiple keys for the same user' do
    first_key = 'AAAAC3NzaC1lZDI1NTE5AAAAIGeVK8hndufeFsIQDgd5tGtLEcYGMjxggHwzCQF+ooUg'
    second_key = 'AAAAC3NzaC1lZDI1NTE5AAAAIKsrFnG8FODegr/4EiAG5NvuLOs7Va+Crv3Gy5WKNoeC'

    let(:title) { 'root_ed25519' }
    let(:params) do
      {
        hostname: 'node.example.com',
      }
    end
    let(:pre_condition) do
      <<~PP
        pubkey::ssh { 'backup_ed25519':
          user     => 'root',
          prefix   => 'backup',
          hostname => 'node.example.com',
        }
      PP
    end
    let(:facts) do
      os_facts.merge({
                       pubkey: {
                         'root_ed25519' => {
                           'type' => 'ssh-ed25519',
                           'key' => first_key,
                           'comment' => 'root_ed25519',
                         },
                         'backup_ed25519' => {
                           'type' => 'ssh-ed25519',
                           'key' => second_key,
                           'comment' => 'backup_ed25519',
                         },
                       },
                     })
    end

    it { is_expected.to compile }

    it {
      is_expected.to contain_file_line('root_ed25519:/root/.ssh/id_ed25519.pub').with(
        path: '/var/cache/pubkey/exported_keys',
        line: 'root_ed25519:/root/.ssh/id_ed25519.pub',
      )
    }

    it {
      is_expected.to contain_file_line('backup_ed25519:/root/.ssh/backup_ed25519.pub').with(
        path: '/var/cache/pubkey/exported_keys',
        line: 'backup_ed25519:/root/.ssh/backup_ed25519.pub',
      )
    }

    it 'exports each key with its own data' do
      expect(exported_resources).to contain_ssh_authorized_key('root_ed25519@node.example.com').with(
        user: 'root',
        type: 'ssh-ed25519',
        key: first_key,
      )
      expect(exported_resources).to contain_ssh_authorized_key('backup_ed25519@node.example.com').with(
        user: 'root',
        type: 'ssh-ed25519',
        key: second_key,
      )
    end
  end

  context 'with legacy username-keyed fact' do
    legacy_key = 'AAAAC3NzaC1lZDI1NTE5AAAAIGeVK8hndufeFsIQDgd5tGtLEcYGMjxggHwzCQF+ooUg'

    let(:title) { 'root_ed25519' }
    let(:params) do
      {
        hostname: 'node.example.com',
      }
    end
    let(:facts) do
      os_facts.merge({
                       pubkey: {
                         'root' => {
                           'type' => 'ssh-ed25519',
                           'key' => legacy_key,
                         },
                       },
                     })
    end

    it { is_expected.to compile }

    it 'still exports the key until the cache is rewritten' do
      expect(exported_resources).to contain_ssh_authorized_key('root_ed25519@node.example.com').with(
        user: 'root',
        type: 'ssh-ed25519',
        key: legacy_key,
      )
    end
  end

  context 'with colon in title' do
    let(:title) { 'bob:rsa' }
    let(:params) do
      {
        type: 'rsa',
        user: 'bob',
      }
    end

    it { is_expected.to raise_error(Puppet::Error, %r{title must not contain ':'}) }
  end
end
