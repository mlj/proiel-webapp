#--
#
# tei.rb - TEI support functions
#
# Copyright 2009 University of Oslo
# Copyright 2009 Marius L. Jøhndal
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
require 'singleton'

module TEI
  # Abbreviations for reference systems supported by the TEI source
  # import adapters.
  TRACKED_REFERENCES = {
    'L'  => 'line=sentence,act=source_division',
    'BC' => 'book=source_division,chapter=sentence',
  }

  REFERENCE_FORMATS = {
    'L'  => 'source="#title#",source_division="#title#, Act #act#",sentence="#title#, #line#"',
    'BC' => 'source="#title#",source_division="#title#, #book#",sentence="#title#, #book#.#chapter#"',
  }

  # Container for import parameters for registered TEI sources.
  class RegisteredSources < Hash
    include Singleton

    SourceDefinition = Struct.new(:language, :abbrev, :file_name, :title, :tracked_references, :reference_format)

    def initialize
      File.open(File.join(File.dirname(__FILE__), 'tei.csv')) do |f|
        f.each_line do |l|
          l.chomp!
          l.gsub!(/#.*$/, '')
          next if l[/^\s*$/]

          language, abbrev_author, abbrev_work, file_name, author, work, reference_system, *rest = l.split(/\s*,\s*/)
          identifier = [abbrev_author, abbrev_work].join('-').downcase.gsub('.', '')
          tracked_references = TRACKED_REFERENCES[reference_system]
          reference_format = REFERENCE_FORMATS[reference_system]
          raise "Invalid reference system #{reference_system}" unless tracked_references
          self[identifier] = SourceDefinition.new(language,
                                                  [abbrev_author, abbrev_work].join(', '),
                                                  file_name,
                                                  [author, work].join(', '),
                                                  tracked_references,
                                                  reference_format)
        end
      end
    end
  end

  class PerseusAdapter
    include Singleton

    def initialize
      stylesheet_file = File.join(File.dirname(__FILE__), 'tei.xsl')
      @stylesheet = XSLT::Stylesheet.new(XML::Document.file(stylesheet_file))
      @catalog_file = File.join(File.dirname(__FILE__), 'catalog')
    end

    def transform(identifier, perseus_data_directory)
      source = RegisteredSources.instance[identifier]
      raise ArgumentError, 'invalid identifier' unless source

      xsl_params = {
        :identifier => "'#{identifier}'",
        :language => "'#{source.language}'",
        :abbrev => "'#{source.abbrev}'",
        :title => "'#{source.title}'",
        :tracked_references => "'#{source.tracked_references}'",
        :reference_format => "'#{source.reference_format}'",
      }

      ENV['XML_CATALOG_FILES'] = @catalog_file

      begin
        xml = XML::Document.file(File.join(perseus_data_directory, source.file_name),
                                 :options => XML::Parser::Options::NOENT)
      rescue LibXML::XML::Parser::ParseError => p
        raise "Invalid TEI file"
      end

      @stylesheet.apply(xml, xsl_params).to_s
    end
  end
end
