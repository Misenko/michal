# Whenever runner dealing with request related periodic tasks
#
class Michal::Whenever::RequestsRunner
  class << self
    # Marks finished tasks when their data is available
    #
    def mark_finished
      Yell.new :stdout, :name => Object, :level => :debug, :format => Yell::DefaultFormat
      Object.send :include, Yell::Loggable

      Michal::Periodic::RequestWatchdog.new.update_finished_requests
    end

    # Repeates periodic statistics
    #
    def repeate_periodic
      Yell.new :stdout, :name => Object, :level => :debug, :format => Yell::DefaultFormat
      Object.send :include, Yell::Loggable

      Michal::Periodic::RequestRepeater.new.repeate_requests
    end
  end
end
