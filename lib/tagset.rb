# encoding: UTF-8
#--
#
# Copyright 2012 University of Oslo
# Copyright 2012 Marius L. Jøhndal
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

class TagSet
  def initialize(name)
    @tags = YAML.load_file(Rails.root.join('lib', 'tagset', "#{name}.yml")).stringify_keys.freeze
  end

  def tags
    @tags.keys
  end

  def [](tag)
    @tags[tag.to_s]
  end

  def has_tag?(tag)
    @tags.has_key?(tag.to_s)
  end

  def all
    @tags
  end
end

class TagSets
  def self.load_tag_set(name)
    @@tag_sets ||= {}
    @@tag_sets[name.to_s] = TagSet.new(name.to_s)
  end

  def self.add_dynamic_tag_set(name, klass)
    @@tag_sets ||= {}
    @@tag_sets[name.to_s] = klass.new(name)
  end

  def self.has_tag_set?(name)
    @@tag_sets.has_key?(name.to_s)
  end

  def self.[](name)
    @@tag_sets[name.to_s]
  end
end

class LanguageTagSet < TagSet
  def initialize(name)
    @tags = Hash[*ISOCodes.all_iso_639_3_codes.map do |tag|
      [tag.to_s, ISOCodes.find_language(tag).reference_name]
    end.flatten].freeze
  end
end

class MorphologyTagSet < TagSet
  def initialize(name)
    @tags = {}
  end
end

TagSets.load_tag_set 'information_structure'
TagSets.load_tag_set 'part_of_speech'
#TagSets.add_dynamic_tag_set 'morphology', MorphologyTagSet
TagSets.add_dynamic_tag_set 'language', LanguageTagSet

module ActiveRecord
  module Validations
    module ClassMethods
      # Validates that the value of the specified attribute is a valid tag
      # in the given tag set.
      def validates_tag_set_inclusion_of(attribute, tag_set, options = {})
        raise ArgumentError, "invalid tag set #{tag_set}" unless TagSets.has_tag_set?(tag_set)

        validates_inclusion_of attribute, options.merge({ :in => TagSets[tag_set].tags })
      end
    end
  end
end
