module Michal::Authenticators
  require 'michal/authenticators/base_authn_mixin'
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
