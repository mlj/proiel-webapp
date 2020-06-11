#--
#
# Copyright 2007-2016 University of Oslo
# Copyright 2007-2017 Marius L. Jøhndal
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
  change_logging

  blankable_attributes :author

  validates_presence_of :title
  validates_presence_of :citation_part

  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false

  has_many :source_divisions
  has_many :sentences, through: :source_divisions

  has_many :dependency_alignment_terminations

  store :additional_metadata, accessors: Proiel::Metadata.fields

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
    Source.pluck(:language_tag).uniq.map { |l| LanguageTag.new(l) }.sort_by(&:to_label)
  end

  def to_label
    title
  end

  # Returns the name of the language of the source.
  def language_name
    language.name
  end

  # Returns a generated metadata field containing the names of all annotators
  # and the number of sentences each has annotated.
  def annotator
    Sentence.
      includes(:source_division, :annotator).
      where("source_divisions.source_id" => self).
      where("annotated_by IS NOT NULL").
      group(:annotator).
      count.
      sort_by { |u, n| -n }.
      map { |u, n| [u.full_name, "#{n} sentence".pluralize(n)] }.
      map { |u, n| "#{u} (#{n})" }.
      to_sentence
  end

  # Returns a generated metadata field containing the names of all reviewers
  # and the number of sentences each has reviewed.
  def reviewer
    Sentence.
      includes(:source_division, :reviewer).
      where("source_divisions.source_id" => self).
      where("reviewed_by IS NOT NULL").
      group(:reviewer).
      count.
      sort_by { |u, n| -n }.
      map { |u, n| [u.full_name, "#{n} sentence".pluralize(n)] }.
      map { |u, n| "#{u} (#{n})" }.
      to_sentence
  end

  # Generates a human-readable ID for the source.
  def human_readable_id
    code
  end

  # Move all source divisions from +other_source_ to this source. If +position+
  # is +:append+, the source divisions from +other_source+ will be placed after
  # existing ones in this source. If +position+ is +:preprend:, they will be
  # placed before them.
  def merge_with_source!(other_source, position = :append)
    Source.transaction do
      case position
      when :append
        reassign_source_divisions!(other_source, source_divisions.maximum(:position) + 1)
      when :prepend
        #self.tokens.sort { |x, y| y.token_number <=> x.token_number }.each do |t|
        position_base = other_source.source_divisions.count

        self.source_divisions.order('position DESC').each do |sd|
          sd.update_attributes! :position => sd.position + position_base
        end

        reassign_source_divisions!(other_source)
      else
        raise ArgumentError, 'invalid position' unless position == :append or position == :prepend
      end
    end

    other_source.reload
    self.reload
  end

  # Returns the alignment source if any descendant object is aligned to an object in another source.
  #
  # This does not verify that all descendants with alignments actually refer to the
  # same source.
  def inferred_aligned_source
    source_divisions.each do |sd|
      i = sd.inferred_aligned_source
      return i unless i.nil?
    end

    nil
  end

  private

  def reassign_source_divisions!(other_source, position_base = 0)
    Source.transaction do
      other_source.source_divisions.order(:position).each_with_index do |sd, i|
        sd.update_attributes! :position => i + position_base, :source_id => self.id
      end
    end
  end
end
