# frozen_string_literal: true

require 'sidekiq/web_custom/processor'

RSpec.describe Sidekiq::WebCustom::Processor do

  let(:worker) { Sidekiq::WebCustom::Processor::TestWorker }
  let(:queue) { Sidekiq::Queue.new(worker.sidekiq_options['queue']) }
  let(:manager) { nil }
  let(:options) { Sidekiq.options.merge(fetch: Sidekiq::BasicFetch) }
  let(:job_count) { 0 }
  before do
    class Sidekiq::WebCustom::Processor::TestWorker
      include Sidekiq::Worker
      sidekiq_options queue: :test_queue
      def perform(*)
        Sidekiq.logger.info "received test message"
      end
    end
    queue.clear
    allow(Sidekiq).to receive(:logger).and_return(Logger.new('/dev/null'))
    allow(Sidekiq.logger).to receive(:info)
    allow(Sidekiq.logger).to receive(:error)
    job_count.times { worker.perform_async }
  end
  after { queue.clear }


  describe '.execute' do
    subject { described_class.execute(max: 1, queue: queue) }

    it do
      expect_any_instance_of(described_class).to receive(:__execute)

      subject
    end
  end

  describe '.execute_job' do
    subject { described_class.execute_job(job: job) }

    let(:job_count) { 1 }
    let(:job) { queue.first }

    it do
      expect_any_instance_of(described_class).to receive(:__execute_job)

      subject
    end
  end

  describe '.__processor__' do
    subject { described_class.__processor__(params) }

    let(:params) { { queue: queue_in, options: options }.compact }
    let(:options) { nil }
    let(:queue_in) { Sidekiq::Queue.new('queueeeeeeee') }
    context 'when fetch is populated' do
      let(:options) { Sidekiq.options.merge(fetch: Sidekiq::BasicFetch.new(Sidekiq.options))}

      it { is_expected.to be_a(described_class) }
    end

    context 'when queue is a string' do
      let(:queue_in) { 'some_queue' }

      it { is_expected.to be_a(described_class) }
    end

    it { is_expected.to be_a(described_class) }
  end

  describe '.initialize' do
    subject { described_class.new(manager: manager, options: options, queue: queue) }

    it do
      expect(subject).to be_a(described_class)
    end
  end

  describe '.__execute_job' do
    subject { described_class.execute_job(job: job) }

    let(:job_count) { 1 }
    let(:job) { queue.first }

    context 'when error occurs during perform' do
      before { allow_any_instance_of(worker).to receive(:perform).and_raise(StandardError, 'Failed to do work') }

      it { is_expected.to eq false }

      it do
        expect(Sidekiq.logger).to receive(:error).with(/Manually processed work unit failed/)

        subject
      end

      it do
        expect(job).to_not receive(:delete)

        subject
      end
    end

    context 'when delete job failure' do
      before { allow(job).to receive(:delete).and_raise(StandardError, 'Failed to delete') }

      it { is_expected.to eq false }

      it do
        expect(Sidekiq.logger).to receive(:fatal).with(/Manually processed work unit failed to be dequeued/)

        subject
      end
    end

    it do
      expect(job).to receive(:delete)

      subject
    end

    it do
      expect_any_instance_of(worker).to receive(:perform)

      subject
    end

    it { is_expected.to eq true }
  end

  describe '.__execute' do
    subject { described_class.execute(max: max, queue: queue) }

    let(:job_count) { 10 }
    let(:max) { job_count }

    it 'pulls max jobs from queue' do
      expect(Sidekiq.logger).to receive(:info).with('received test message').exactly(max).times

      subject
    end

    it { expect { subject }.to change { queue.size }.to(0) }
    it { expect(subject).to eq(max) }

    context 'when no jobs' do
      let(:job_count) { 0 }
      it { expect(subject).to eq(0) }
      it { expect { subject }.to_not change { queue.size } }
    end

    context 'when max is > than size of queue' do
      let(:max) { 30 }

      it 'pulls all jobs from queue' do
        expect(Sidekiq.logger).to receive(:info).with('received test message').exactly(job_count).times

        subject
      end

      it { expect { subject }.to change { queue.size }.to(0) }
      it { expect(subject).to eq(job_count) }
    end

    context 'when max is < than size of queue' do
      let(:max) { job_count - 1 }

      it 'pulls max jobs from queue' do
        expect(Sidekiq.logger).to receive(:info).with('received test message').exactly(max).times

        subject
      end

      it { expect { subject }.to change { queue.size }.to(job_count - max) }
      it { expect(subject).to eq(max) }
    end

    context 'when failure occurs' do
      let(:job_count) { 1 }
      before do
        allow(Sidekiq.logger).to receive(:fatal)
        allow_any_instance_of(worker).to receive(:perform).and_raise(ArgumentError, 'Expect this to raise stuff')
      end
      it { expect { subject }.to change { queue.size }.to(job_count - 1) }
      it { expect { subject }.to_not raise_error }
      it do
        expect(Sidekiq.logger).to receive(:fatal).with(/Processor Execution interrupted/)

        subject
      end

      it do
        expect(Sidekiq.logger).to receive(:warn).with(/Manual execution has terminated. Received error/)

        subject
      end
    end

    context 'when break bit is set' do
      let(:job_count) { 1 }
      before { Thread.current[Sidekiq::WebCustom::BREAK_BIT] = 1 }
      after { Thread.current[Sidekiq::WebCustom::BREAK_BIT] = nil }

      it { expect { subject }.to_not change { queue.size } }
      it { expect(subject).to eq(0) }
      it do
        expect(Sidekiq.logger).to receive(:warn).with(/Yikes -- Break bit has been set/)

        subject
      end
    end
  end
end
