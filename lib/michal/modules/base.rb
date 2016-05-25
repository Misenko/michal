# Base statistic module class
#
class Michal::Modules::Base
  attr_reader :sources, :parameters, :logger

  def initialize(parameters, logger=nil)
    @logger = logger
    @parameters = parameters.to_h.deep_symbolize_keys
  end

  class << self
    # Checks whether class is a statistic module
    #
    # @return [TrueClass|FalseClass] true if class is a statistic module, false otherwise
    def module?
      false
    end

    # List of component for the module
    #
    # @return [Hash] components
    def components
      nil
    end

    # Title of the module
    #
    # @return [String] title
    def title
      nil
    end
  end
end
