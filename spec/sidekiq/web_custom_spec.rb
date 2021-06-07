# frozen_string_literal: true
require 'sidekiq/web_custom'

RSpec.describe Sidekiq::WebCustom do
  before { described_class.reset! }
  describe 'version' do
    it { expect(Sidekiq::WebCustom::VERSION).to be_a String }
    it { expect(Sidekiq::WebCustom::MAJOR).to be_a Integer }
    it { expect(Sidekiq::WebCustom::MINOR).to be_a Integer }
    it { expect(Sidekiq::WebCustom::PATCH).to be_a Integer }
  end

  describe '.config' do
    subject { described_class.config }

    it { expect(subject).to be_a Sidekiq::WebCustom::Configuration }
    it { expect(subject.actions).to be_a Hash }
    it { expect(subject.actions).to_not be_empty }
    it { expect(subject.actions).to eq(described_class.default_available_actions_mapping) }
    it { expect(subject.local_erbs).to be_a Hash }
    it { expect(subject.local_erbs).to_not be_empty }
    it { expect(subject.local_erbs).to eq(described_class.default_local_erb_mapping) }
  end

  describe '.local_erb_mapping' do
    subject { described_class.local_erb_mapping }

    it { is_expected.to be_a Hash }
    it { expect(subject).to_not be_empty }
  end

  describe '.configure' do
    subject { described_class.configure }

    let(:routes) { ::Sidekiq::WebApplication.instance_variable_get(:@routes) }
    let(:routes) do
      ::Sidekiq::WebApplication.instance_variable_get(:@routes).map do |k,v|
        [k,v.map(&:pattern)]
      end.to_h
    end

    it 'injects dependencies' do
      subject

      expect(::Sidekiq::WebAction.included_modules.include?(Sidekiq::WebCustom::WebAction)).to be true
      expect(::Sidekiq::Queue.included_modules.include?(Sidekiq::WebCustom::Queue)).to be true
      expect(::Sidekiq::Job.included_modules.include?(Sidekiq::WebCustom::Job)).to be true
    end

    it 'injects drain route' do
      subject

      expect(routes['POST']).to include('/queues/drain/:name')
    end

    it 'injects job delete' do
      subject

      expect(routes['POST']).to include('/job/delete')
    end

    it 'injects job execute' do
      subject

      expect(routes['POST']).to include('/job/execute')
    end

    it 'validates config' do
      expect(described_class.config).to receive(:validate!).and_call_original

      subject
    end

    context 'with block' do
      subject do
        described_class.configure do |config|
          config.drain_rate = value
        end
      end

      let(:value) { 30 }

      it { expect { subject }.not_to raise_error }
      it do
        subject

        expect(described_class.config.drain_rate).to eq(value)
      end
    end
  end

  describe '.root_path' do
    subject { described_class.root_path }

    it { expect(File.exist?(subject)).to be true }
  end

  describe '.local_erbs_root' do
    subject { described_class.local_erbs_root }

    it { expect(File.exist?(subject)).to be true }
    it { expect(subject).to include(described_class.root_path) }
  end

  describe '.actions_root' do
    subject { described_class.actions_root }

    it { expect(File.exist?(subject)).to be true }
    it { expect(subject).to include(described_class.local_erbs_root) }
  end

  describe '.default_local_erb_mapping' do
    subject { described_class.default_local_erb_mapping }

    it { expect(subject).to be_a Hash }
    it { expect(subject).to_not be_empty }

    it do
      expect(subject.keys).to include(:queues, :retries, :scheduled)
    end
  end

  describe '.default_available_actions_mapping' do
    subject { described_class.default_available_actions_mapping }

    it { expect(subject).to be_a Hash }
    it { expect(subject).to_not be_empty }

    it do
      expect(subject.keys).to include(:queues, :retries, :scheduled)
    end
  end
end
