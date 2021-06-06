# frozen_string_literal: true

require 'sidekiq/web_custom/configuration'

RSpec.describe Sidekiq::WebCustom::Configuration do

  let(:instance) { described_class.new }
  before { Sidekiq::WebCustom.reset! }
  describe '.new' do
    subject { instance }

    it { expect(subject.drain_rate).to eq(described_class::DEFAULT_DRAIN_RATE)  }
    it { expect(subject.max_execution_time).to eq(described_class::DEFAULT_EXEC_TIME)  }
    it { expect(subject.warn_execution_time).to eq(described_class::DEFAULT_WARN_TIME)  }
    it { expect(subject.actions).to eq({})  }
    it { expect(subject.local_erbs).to eq({})  }
  end

  shared_examples 'defined integer methods' do
    subject { instance.public_send("#{method}=", value) }

    let(:value) { 1000 }
    it { expect { subject }.to change { instance.public_send(method) } }

    context 'with invalid value' do
      context 'when float' do
        let(:value) { 10.0 }

        it { expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Expected #{method}/) }
      end

      context 'when string' do
        let(:value) { 'will_fail' }

        it { expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Expected #{method}/) }
      end
    end
  end

  describe '#drain_rate' do
    let(:method) { :drain_rate }

    include_examples 'defined integer methods'
  end

  describe '#max_execution_time' do
    let(:method) { :max_execution_time }

    include_examples 'defined integer methods'
  end

  describe '#max_execution_time' do
    let(:method) { :warn_execution_time }

    include_examples 'defined integer methods'
  end

  describe '#merge' do
    subject(:merge) { instance.merge(base: base, params: params, action_type: action_type) }


    let(:action_type) { nil }

    context 'with actions' do
      before { instance.merge(base: base, params: {}) }

      let(:base) { described_class::ACTIONS }
      let(:params) { Sidekiq::WebCustom.default_available_actions_mapping }

      it { expect { subject }.to change { instance.actions } }

      it do
        subject

        expect(instance.actions).to eq(params)
      end

      context 'with action_type' do
        let(:action_type) { Sidekiq::WebCustom.default_available_actions_mapping.keys.sample.to_sym }
        let(:params) { super()[action_type] }

        it do
          subject

          expect(instance.actions[action_type]).to eq(params)
        end

        context 'with string' do
          let(:action_type) { super().to_s }
          let(:params) { Sidekiq::WebCustom.default_available_actions_mapping[action_type.to_sym] }
          it do
            subject

            expect(instance.actions[action_type.to_sym]).to eq(params)
          end
        end
      end

      context 'when bad params' do
        let(:params) { [] }

        it { expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Expected object for #{base}/) }
      end
    end

    context 'with local_erbs' do
      before { instance.merge(base: base, params: {}) }

      let(:base) { described_class::LOCAL_ERBS }
      let(:params) { Sidekiq::WebCustom.default_local_erb_mapping }

      it { expect { subject }.to change { instance.local_erbs } }

      it do
        subject

        expect(instance.local_erbs).to eq(params)
      end

      context 'when bad params' do
        let(:params) { [] }

        it { expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Expected object for #{base}/) }
      end
    end

    context 'when disallowed base' do
      let(:base) { :dis_allowed_base }
      let(:params) { Sidekiq::WebCustom.default_local_erb_mapping }

      it { expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Unexpected base: #{base}/) }
    end
  end

  describe '#validate!' do
    subject { instance.validate! }

    let(:instance) { Sidekiq::WebCustom.config }
    context 'when local_erbs file does not exist' do
      before do
        allow(File).to receive(:exist?)
        allow(File).to receive(:exist?).with(bad_file_path).and_return(false)
      end
      let(:bad_file_path) { Sidekiq::WebCustom.default_local_erb_mapping.first[1] }

      it do
        expect { subject }.to raise_error(Sidekiq::WebCustom::FileNotFound, /The absolute file path does not exist/)
      end
    end

    context 'when action file does not exist' do
      before do
        allow(File).to receive(:exist?)
        allow(File).to receive(:exist?).with(bad_file_path).and_return(false)
      end
      let(:bad_file_path) { Sidekiq::WebCustom.default_available_actions_mapping.first[1].first[1] }

      it do
        expect { subject }.to raise_error(Sidekiq::WebCustom::FileNotFound, /The absolute file path does not exist/)
      end
    end

    context 'when action_type does not map to local_erb' do
      let(:params) { { drain: __FILE__} }
      let(:action_type) { :undefined_action_type }
      let(:action) { action_type }
      before { instance.merge(base: described_class::ACTIONS, params: params, action_type: action ) }

      it do
        expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Unexpected actions keys/)
      end

      context 'when no action_type passed' do
        let(:params) { { action_type => super() } }
        let(:action) { nil }
        it do
          expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Unexpected actions keys/)
        end
      end
    end

    context 'when warn_execution_time greater than max_execution_time' do
      before do
        instance.warn_execution_time = instance.max_execution_time + 1
      end

      it do
        expect { subject }.to raise_error(Sidekiq::WebCustom::ArgumentError, /Expected warn_execution_time to be less /)
      end
    end

    it 'defines convenience methods' do
      subject

      expect(instance.methods).to include(*Sidekiq::WebCustom.default_local_erb_mapping.keys.map { |c| "actions_for_#{c}".to_sym})
    end
  end
end
