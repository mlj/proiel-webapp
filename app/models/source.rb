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

class Source < ActiveRecord::Base
  attr_accessible :source_id, :position, :title,
    :aligned_source_division_id, :presentation_before, :presentation_after

  change_logging

  blankable_attributes :author, :edition

  validates_presence_of :title
  validates_presence_of :citation_part

  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false

  has_many :source_divisions

  composed_of :metadata, :class_name => 'Metadata', :mapping => %w(tei_header)

  has_many :dependency_alignment_terminations

  # Returns a citation for the source.
  def citation
    citation_part
  end

  # The author and the title of the source properly formatted as a single
  # string.
  def author_and_title
    [author, title].compact.join(': ')
  end

  # Returns an array of all languages represented in sources.
  def self.represented_languages
    Source.uniq.pluck(:language_tag).map { |l| LanguageTag.new(l) }.sort_by(&:to_label)
  end

  def to_label
    title
  end

  # Returns the name of the language of the source.
  def language_name
    language.name
  end

  # Returns a hash with aggregated status statistics for the source.
  def aggregated_status_statistics
    Sentence.where(:source_division_id => source_divisions).count(:group => :status_tag)
  end

  # Returns a hash with aggregated status statistics for all sources.
  def self.aggregated_status_statistics
    Sentence.count(:group => :status_tag)
  end

  # Generates a human-readable ID for the source.
  def human_readable_id
    if citation_part.blank?
      id.to_s
    else
      citation_part.downcase.gsub(/[^\w]+/, '_').sub(/_$/, '')
    end
  end
end
