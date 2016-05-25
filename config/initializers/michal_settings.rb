require 'configliere'
require 'yaml'

DEFAULT_CONF = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', 'michal'))
ETC_CONF = File.expand_path(File.join('/', 'etc', 'michal'))
HOME_CONF = File.expand_path(File.join('~', '.michal'))
SOURCES = 'sources'

def load_confs(location)
  confs = Dir.glob(File.join(location, '*.yml'))
  confs.each do |file|
    Settings File.basename(file).chomp('.yml').to_sym => YAML.load(File.open(file))
  end
end

def load_sources(location)
  confs = Dir.glob(File.join(location, '*.yml'))
  confs.each do |file|
    Settings SOURCES => { File.basename(file).chomp('.yml').to_sym => YAML.load(File.open(file)) }
  end
end

locations = [HOME_CONF, ETC_CONF, DEFAULT_CONF]
locations.each do |location|
  if File.directory? location
    load_confs location

    sources = File.join(location, SOURCES)
    if File.directory? sources
      load_sources sources
    end

    break
  end
end

Settings.resolve!
