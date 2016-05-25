class Michal::Errors::SourcesError < Michal::Errors::StandardError; end

module Michal::Errors::Sources
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
