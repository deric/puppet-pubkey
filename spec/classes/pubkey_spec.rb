# frozen_string_literal: true

require 'spec_helper'

describe 'pubkey' do
  _, os_facts = on_supported_os.first
  context "with default parameters" do
    let(:facts) { os_facts }

    it { is_expected.to compile.with_all_deps }
  end

  context 'multiple keys' do
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

    it { is_expected.to compile.with_all_deps }
  end
end
