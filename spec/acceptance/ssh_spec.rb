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
        :catch_failures => false,
        :debug          => false,
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
  end
end
