# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

module Proiel
  module Jobs
    class Exporter < Job
      FORMATS = {
        'proiel' =>   [PROIELXMLExporter, 'xml'],
        'tigerxml' => [TigerXMLExporter,  'tiger'],
        'tiger2' =>   [Tiger2Exporter,    'tiger2'],
        'text' =>     [TextExporter,      'txt'],
        'json' =>     [JSONExporter,      'json'],
      }

      def self.available_exporters
        FORMATS.keys
      end

      # ==== Options
      # * <tt>:id</tt> - If set, only exports the source with the given ID. If not set,
      # all sources are expored.
      # * <tt>:source_division</tt> - If set to a regular expression, only
      # exports source divisions whose titles match the regular expression.
      # * <tt>:format</tt> - The export format to use. Valid export formats can
      # be retrieved using <tt>available_exporters</tt>. This can be a string
      # or an array of strings. The default is to export the <tt>proiel</tt>
      # format.
      # * <tt>:mode</tt> - If set to 'all', will export all sentences. If
      # 'reviewed', will export only those sentences that have
      # <tt>status_tag</tt> set to <tt>reviewed</tt>. The default is
      # <tt>all<tt>.
      # * <tt>:semantic_tags</tt> - If true, will also export semantic tags.
      # * <tt>:export_directory</tt> - If set, overrides the default export
      # directory, which is provided by
      # <tt>Proiel::Application.config.export_directory_path</tt>.
      # * <tt>:remove_cycles</tt> - If set, will remove cycles. This option is
      # only relevant to the TigerXML export format. Valid values are
      # <tt>all</tt> and <tt>heads</tt>.
      def initialize(logger = Rails.logger, options = {})
        super(logger)

        @options = options
        @options.symbolize_keys!
        @options.reverse_merge! format: 'proiel', mode: 'all', semantic_tags: false

        @options[:format] = [*@options[:format]]
        raise ArgumentError, 'invalid format' unless @options[:format].all? { |format| FORMATS.has_key?(format) }

        raise ArgumentError, 'invalid mode' unless %w(all reviewed).include?(@options[:mode])
      end

      def run_once!
        @options[:format].each do |format|
          klass, suffix = FORMATS[format]

          options = {}
          options[:reviewed_only] = true if @options[:mode] == 'reviewed'
          options[:sem_tags] = true if @options[:semantic_tags]
          options[:cycles] = @options[:remove_cycles] if @options[:remove_cycles]

          # Prepare destination directory
          directory = @options[:export_directory] || Proiel::Application.config.export_directory_path
          Dir::mkdir(directory) unless File::directory?(directory)

          # Find sources and iterate them
          sources = @options[:id] ? Source.find_all_by_id(@options[:id]) : Source.all

          sources.each do |source|
            file_name = File.join(directory, "#{source.human_readable_id}.#{suffix}")

            if @options[:source_division]
              options[:source_division] = source.source_divisions.select { |sd| sd.title =~ Regexp.new(@options[:source_division]) }.map(&:id)
            end

            begin
              @logger.info { "#{self.class}: Exporting source ID #{source.id} as #{file_name}" }
              klass.new(source, options).write(file_name)
            rescue Exception => e
              @logger.error { "#{self.class}: Error exporting text #{source.human_readable_id} using #{klass}: #{e}\n" + e.backtrace.join("\n") }
            end
          end
        end
      end
    end
  end
end
