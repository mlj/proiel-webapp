TAGGER_CONFIG_FILE = File.join(File.expand_path(File.dirname(__FILE__)), '..', 'tagger.yml')
TAGGER_DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib', 'morphology')
TAGGER = Tagger::Tagger.new(TAGGER_CONFIG_FILE, :data_directory => TAGGER_DATA_PATH, :logger => RAILS_DEFAULT_LOGGER)
