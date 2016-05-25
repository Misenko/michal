require 'timeout'
require 'sidekiq-status'

# Helper Sidekiq class representing batch of Sidekiq jobs
#
class Michal::Sidekiq::Batch
  attr_accessor :jobs, :timeout

  POLLING_TIME = 60

  # Constructor
  #
  # @param [Fixnum] timeout during which jobs have to finish (in seconds)
  def initialize(timeout)
    @timeout = timeout
    @jobs = []
  end

  # Waits for jobs to finish or throws an exception if they won't finish within
  # a timeout
  #
  def wait
    Timeout::timeout(timeout) do
      until(done?)
        sleep(POLLING_TIME)
      end
    end
  end

  # Adds job among jobs
  #
  # @param [Sidekiq::Job] job
  def <<(job)
    jobs << job
  end

  # Checks whether the whole batch of jobs is done
  #
  # @return [TrueClass|FalseClass] true if jobs are done, false otherwise
  def done?
    jobs.delete_if { |job| Sidekiq::Status::complete? job }

    jobs.empty?
  end
end
