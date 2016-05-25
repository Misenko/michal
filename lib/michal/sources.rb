module Michal::Sources
  require 'michal/sources/base'
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
