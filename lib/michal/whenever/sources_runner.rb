require 'yell'

# Whenever runner copying OpenNebula sources' content into MongoDB
#
class Michal::Whenever::SourcesRunner
  class << self
    def update_sources
      Yell.new :stdout, :name => Object, :level => :debug, :format => Yell::DefaultFormat
      Object.send :include, Yell::Loggable

      types = ['opennebula']

      Settings[:sources].each_pair do |key, value|
        if types.include? value[:type]
          updater = Michal::Periodic::OpenNebulaDataUpdater.new key
          updater.update_data
        end
      end
    end
  end
end
