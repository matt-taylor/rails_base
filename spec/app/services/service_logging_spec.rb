RSpec.describe RailsBase::ServiceLogging do
	let(:instance) { MyHardWorker2.new }
	let(:msg) { 'msg' }
	let(:logger) { NullLogger.new }
	before do
		# this should be fixed, but calling it a different name was the easiest work around
		# bundle exec rspec --seed 43283
		# https://makandracards.com/makandra/47189-rspec-how-to-define-classes-for-specs
		class MyHardWorker2
			include RailsBase::ServiceLogging
		end
	end

	describe '#log' do
		before { allow(instance).to receive(:logger).and_return(logger) }

		shared_examples 'sends to logger' do
			let(:message) { "#{instance.log_prefix}: #{msg}" }
			it 'sends to correct method' do
				expect(logger).to receive(method).with(message)

				subject
			end

			context 'with modifited service_id' do
				let(:message) { "[#{instance.class_name}-this-is-custom]: #{msg}" }
				before do
					class MyHardWorker2
						def service_id
							'this-is-custom'
						end
					end
				end

				it 'sends modified service_id' do
					expect(logger).to receive(method).with(message)

					subject
				end
			end

			context 'with modifited class_name' do
				let(:message) { "[custom-class-name-#{instance.service_id}]: #{msg}" }
				before do
					class MyHardWorker2
						def class_name
							'custom-class-name'
						end
					end
				end

				it 'sends modified service_id' do
					expect(logger).to receive(method).with(message)

					subject
				end
			end
		end

		describe '#debug' do
			subject(:debug) { instance.log(level: method, msg: msg) }

			let(:method) { :debug }
			include_examples 'sends to logger'
		end

		describe '#info' do
			subject(:info) { instance.log(level: method, msg: msg) }

			let(:method) { :info }
			include_examples 'sends to logger'
		end

		describe '#warn' do
			subject(:warn) { instance.log(level: method, msg: msg) }

			let(:method) { :warn }
			include_examples 'sends to logger'
		end

		describe '#error' do
			subject(:error) { instance.log(level: method, msg: msg) }

			let(:method) { :error }
			include_examples 'sends to logger'
		end

		describe '#fatal' do
			subject(:fatal) { instance.log(level: method, msg: msg) }

			let(:method) { :fatal }
			include_examples 'sends to logger'
		end
	end

end
