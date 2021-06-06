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
    job_count.times { worker.perform_async }
  end
  after { queue.clear }


  describe '.execute' do
    xit 'creates processor instance' do
    end

    xit 'calls __execute' do
      expect_any_instance_of(described_class).to receive(:__execute)
    end
  end

  describe '.execute_job' do
  end

  describe '.__processor__' do
  end

  describe '.initialize' do
    subject { described_class.new(manager: manager, options: options, queue: queue) }

    it do
      expect(subject).to be_a(described_class)
    end
  end

  describe '.__execute_job' do

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
      context 'when not using BasicFetch' do
        let(:options) { super().merge(fetch: Sidekiq::SuperFetch) }
        before do
          stub_const('Sidekiq::SuperFetch')
          allow_any_instance_of(described_class).to receive(:process_one).and_raise(Exception)
        end
      end
    end

    context 'when break bit is set' do
    end
  end
end
