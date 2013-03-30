require 'proiel/dependency_graph'
require 'proiel/tagger'

require 'yaml'

module PROIEL
  INFERENCES = YAML::load_file(File.join(Rails.root.join('lib', 'proiel', 'inferences.yml'))).freeze
end
