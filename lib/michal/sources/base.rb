# Base source class
#
class Michal::Sources::Base
  attr_reader :logger, :name

  def initialize(name, logger)
    @logger = logger
    @name = name
  end
end
