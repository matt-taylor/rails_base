RSpec.describe RailsBase::ServiceBase do
	subject { MyHardWorker.call(params) }
	let(:params) { { proc: proc } }

	let(:proc) { ->(poop) { true } }
	before do
		class MyHardWorker < RailsBase::ServiceBase
			def call
				context.proc.call(context)
			end

			def validate!
				raise ArgumentError, 'unkown argument' unless context.proc
			end
		end
	end

	describe '#validate!' do
		context 'when correct params' do
			it { expect { subject }.not_to raise_error }
		end

		context 'when incorrect params' do
			let(:params) { }
			it { expect { subject }.to raise_error(ArgumentError, 'unkown argument') }
		end
	end

	describe '#call' do
		context 'when interactor failure' do
			let(:proc) { ->(poop) { poop.fail!(message: :failure) } }

			it { expect(subject.failure?).to be true }
			it { expect(subject.message).to eq(:failure) }
		end

		context 'when other error type' do
			before do
				class CustomErrorClass < StandardError; end;
			end
			let(:proc) { ->(poop) { raise CustomErrorClass } }

			it { expect { subject }.to raise_error(CustomErrorClass) }
		end

		it { expect(subject.success?).to be true }
	end
end
