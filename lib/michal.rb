# Main module for custom libraries
#
module Michal
  require 'active_support/all'
  require 'json'

  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
