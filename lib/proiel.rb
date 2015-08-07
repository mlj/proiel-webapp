# encoding: UTF-8
#--
#
# Copyright 2013, 2015 University of Oslo
# Copyright 2013, 2014, 2015 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

autoload :PROIELXMLExporter, 'proiel_xml_exporter'
autoload :PROIELXMLImporter, 'proiel_xml_importer'

autoload :GraphvizVisualizer, 'graph_visualization'
autoload :LatexGlossingExporter, 'latex_glossing_exporter'
autoload :ExternalLinkMapper, 'external_link_mapper'
autoload :BibleExternalLinkMapper, 'external_link_mapper'
autoload :BiblosExternalLinkMapper, 'external_link_mapper'

module Proiel
  # The application version
  VERSION = [1, 5, 2]

  # Returns the application version as a dotted string.
  def self.version
    VERSION.join('.')
  end

  autoload :TokenAnnotationValidator, 'annotation_validator'
  autoload :SentenceAnnotationValidator, 'annotation_validator'
  autoload :Statistics, 'statistics'

  module Jobs
    autoload :Job, 'jobs'
    autoload :DatabaseChecker, 'jobs/database_checker'
    autoload :DatabaseValidator, 'jobs/database_validator'
    autoload :AnnotationValidator, 'jobs/annotation_validator'
    autoload :Exporter, 'jobs/exporter'
  end

  autoload :PathHelpers, 'path_helpers'
  extend PathHelpers

  autoload :Metadata, 'metadata'
end

require 'presentation'
require 'ordering'
require 'blankable'

require 'proiel/dependency_graph'
require 'proiel/tagger'

require 'yaml'

module PROIEL
  INFERENCES = YAML::load_file(File.join(Rails.root.join('lib', 'proiel', 'inferences.yml'))).freeze
end
