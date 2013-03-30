# encoding: UTF-8
#--
#
# Copyright 2012, 2013 University of Oslo
# Copyright 2012, 2013 Marius L. Jøhndal
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

module TagObjectMixin
  class << self
    def included(base)
      base.extend ClassMethods
    end
  end

  module ClassMethods
    # Loads a static model from a file.
    def model_file_name(file_name)
      full_file_name = Rails.root.join(Proiel::Application.config.tagset_file_path, file_name)
      #@model = JSON.parse(File.read(file_name)).freeze
      @model = YAML.load_file(full_file_name).stringify_keys.freeze
    end

    # Sets a dynamic model. The proxy generator object should behave like a
    # Hash-like object and minimally respond to +has_key?+, +keys+, +to_hash+ and
    # +[]+. The objects returned by +[]+ should minimally respond to valid
    # attributes of the model and return their values.
    def model_generator(proxy_object)
      @model = proxy_object
    end

    def all
      tags.map { |tag| self.new(tag.to_s) }
    end

    def to_hash
      @model.to_hash
    end

    def tags
      @model.keys
    end

    def include?(tag)
      if tag.nil?
        false
      else
        @model.has_key?(tag.to_s)
      end
    end

    def find(tag)
      if tag.nil?
        nil
      else
        self.new(tag.to_s)
      end
    end

    def [](tag)
      find(tag)
    end

    def find_model_object(tag)
      if tag.nil?
        nil
      else
        @model[tag.to_s]
      end
    end
  end
end

# A tag object presenting the value of a tag attribute. Tag objects are (value
# objects)[http://c2.com/cgi/wiki?ValueObject] intended for attributes that can
# have a value from a finite set of strings, where each string maps to
# additional (immutable) information, e.g. a human-readable description of the
# semantics of the attribute value in question.
class TagObject
  include Comparable
  include TagObjectMixin

  attr_reader :tag

  def initialize(tag)
    @tag = tag.to_s
    @obj = self.class.find_model_object(tag.to_s)
    raise "invalid tag #{tag}" if @obj.nil?
  end

  def <=>(o)
    @tag <=> o.tag
  end

  def to_s
    @tag
  end

  def method_missing(m, *args)
    if @obj and @obj.has_key?(m.to_s)
      if args.empty?
        @obj[m.to_s]
      else
        raise ArgumentError, "wrong number of arguments #{args.count} for 0)"
      end
    else
      super m, *args
    end
  end
end

module ActiveRecord
  module Validations
    module ClassMethods
      def tag_attribute(part_id, attribute, tag_klass, options = {})
        new_options = options.dup
        new_options[:message] = "%{value} is not a valid #{tag_klass.to_s.underscore.humanize.downcase}" unless options[:message]
        new_options[:in] = tag_klass # tag_klass responds to include?
        validates_inclusion_of attribute, new_options

        new_options = options.dup
        new_options[:mapping] = [attribute, 'to_s']
        new_options[:converter] = proc { |x| tag_klass.new(x) }
        new_options[:class_name] = tag_klass.to_s
        composed_of part_id, new_options
      end
    end
  end
end
