class Michal::Errors::DataLoadersError < Michal::Errors::StandardError; end

module Michal::Errors::DataLoaders
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
