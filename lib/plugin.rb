# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Marius L. Jøhndal
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
require 'stringio'

module PROIEL
  @@external_link_mappers = []
  @@graph_visualizers = []
  @@exporters = []

  def self.register_plugin(klass)
    raise ArgumentError, 'not a klass' unless klass.is_a?(Class)

    begin
      instance = klass.instance
    rescue Exception => e
      Rails.logger.error "Error initializing plugin #{klass}: #{e}"
      Rails.logger.error e.backtrace.join("\n")
      STDERR.puts "Error initializing plugin #{klass}: #{e}"
      STDERR.puts e.backtrace.join("\n")
    else
      case instance
      when ExternalLinkMapper
        @@external_link_mappers << instance
      when GraphVisualizer
        @@graph_visualizers << instance
      when Exporter
        @@exporters << instance
      else
        Rails.logger.error "Error initializing plugin #{c}: not a valid plugin class"
      end
    end
  end

  def self.external_link_mappers
    @@external_link_mappers
  end

  def self.graph_visualizers
    @@graph_visualizers
  end

  def self.exporters
    @@exporters
  end

  def self.load_plugins
    Dir[Rails.root.join('plugins', '**', '*.rb')].each do |plugin|
      next if plugin[/_test\.rb$/]

      Rails.logger.info "Loading plugin #{plugin}..."
      begin
        require plugin
      rescue Exception => msg
        Rails.logger.error "Error loading plugin #{plugin}: #{msg}"
      end
    end

    Rails.logger.info "Registered #{self.external_link_mappers.count} external link mappers"
    Rails.logger.info "Registered #{self.graph_visualizers.count} graph visualizers"
    Rails.logger.info "Registered #{self.exporters.count} exporters"
  end

  class Plugin
    include Singleton

    attr_reader :identifier, :name

    # Initializes the plugin with a unique identifier and a
    # human-readable name, which will be used whenever the plugin's
    # functionality is exposed to end-users.
    def initialize(identifier, name)
      @identifier = identifier
      @name = name
    end
  end

  class GraphVisualizer < Plugin
    # Generates an image visualising the dependency graph.
    def generate(sentence, options = {})
      nil
    end
  end

  class ExternalLinkMapper < Plugin
    # True if this link mapper applies to the citation provided.
    def applies?(citation)
      false
    end

    # Generates an external URL corresponding to the citation provided. May
    # raise +ArgumentError+ if the citation cannot be handled. The caller
    # can check this by testing +applies?+ on the citation.
    def to_url(citation)
      raise ArgumentError, 'cannot map citation to link'
    end
  end

  class Exporter < Plugin
    # True if this exporter applies to the provided object. Provided
    # objects will be sources, source divisions, sentences, tokens or
    # lemmata.
    def applies?(object)
      false
    end

    # Returns the MIME type for the export of the provided object.
    def mime_type(object)
      nil
    end

    # Generates an export form for the provided object.
    def generate(object, options = {})
      raise ArgumentError, 'cannot export object'
    end
  end
end
