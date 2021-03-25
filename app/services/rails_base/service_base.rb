require 'interactor'

class RailsBase::ServiceBase
	include Interactor
  include RailsBase::ServiceLogging

  def self.inherited(subclass)
	  # Add the base logging to the subclass.
	  # Since this is done at inheritence time it should always be the first and last hook to run.
    subclass.around(:service_base_logging)
	  subclass.around(:internal_validate)
	end

  def validate!
    # overload from child
  end

  def internal_validate(interactor)
    # call validate that is overidden from child
    begin
      validate!
    rescue StandardError => e
      log(level: :error, msg: "Error during validation. #{e.message}")
      raise
    end

    # call interactor
    interactor.call
  end

	def service_base_logging(interactor)
	  beginning_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Pre processing stats
    log(level: :info, msg: 'Start')

    # Run the job!
    interactor.call

    # Set status for use in ensure block
    status = :complete

  # Capture Interactor::Failure for logging purposes, then reraise
  rescue ::Interactor::Failure
    # set status for use in ensure block
    status = :failure

    # Reraise to let the core Interactor handle this
    raise
  # Capture exception explicitly to try to logging purposes. Then reraise.
  rescue ::Exception => e # rubocop:disable Lint/RescueException
    # set status for use in ensure block
    status = :error

    # Log error
    log(level: :error, msg: "Error #{e.class.name}")

    raise
  ensure
    # Always log how long it took along with a status
    finished_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ((finished_time - beginning_time) * 10).round
    log(level: :info, msg: "Finished with [#{status}]...elapsed #{elapsed}s")
  end
end
