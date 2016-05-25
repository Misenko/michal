module Michal::DataLoaders
  Dir.glob(File.join(File.dirname(__FILE__), "#{self.name.demodulize.underscore}", '*.rb')) { |file| require file.chomp('.rb') }
end
