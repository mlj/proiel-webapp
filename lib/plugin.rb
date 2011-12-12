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

module PROIEL
  @@external_link_mappers = []
  @@graph_visualizers = []

  def self.register_plugin(klass)
    raise ArgumentError, 'not a klass' unless klass.is_a?(Class)

    begin
      instance = klass.instance
    rescue Exception => msg
      Rails.logger.error "Error initializing plugin #{klass}: #{msg}"
    else
      case instance
      when ExternalLinkMapper
        @@external_link_mappers << instance
      when GraphVisualizer
        @@graph_visualizers << instance
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
end
