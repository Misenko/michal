class Michal::Errors::DataLoaders::OpenNebulaError < Michal::Errors::DataLoadersError; end

module Michal::Errors::DataLoaders::OpenNebula
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
