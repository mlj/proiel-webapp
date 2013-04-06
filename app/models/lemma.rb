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

class Lemma < ActiveRecord::Base
  attr_accessible :lemma, :variant, :short_gloss, :full_gloss, :sort_key,
    :foreign_ids, :language_tag, :part_of_speech_tag

  change_logging

  blankable_attributes :foreign_ids, :full_gloss, :short_gloss, :sort_key,
    :variant

  has_many :tokens
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false
  tag_attribute :part_of_speech, :part_of_speech_tag, PartOfSpeechTag, :allow_nil => false

  validates_presence_of :lemma
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  validates_uniqueness_of :lemma, :scope => [:language_tag, :part_of_speech_tag, :variant]

  # A lemma that matches a prefix. The prefixes are given in +queries+,
  # which should be an array of strings on the form +foo+ or +foo#1+, where
  # +foo+ is a prefix of all lemmata to be matched, and +1+ is a variant
  # number required to be present.
  def self.by_completions(queries)
    statement = queries.map do |query|
      lemma, variant = query.split('#')
      variant.blank? ? '(lemma LIKE ?)' : '(lemma LIKE ? AND variant = ?)'
    end.join(' OR ')

    terms = queries.map do |query|
      lemma, variant = query.split('#')
      if variant.blank?
        "#{lemma}%"
      else
        ["#{lemma}%", variant]
      end
    end.flatten

    where(statement, *terms)
  end

  # Returns the export-form of the lemma.
  def export_form
    self.variant ? "#{self.lemma}##{self.variant}" : self.lemma
  end

  def to_label
    export_form
  end

  # Returns a summary description for the part of speech. This is a
  # convenience function for
  # +lemma.morph_features.pos_summary(options)+.
  #
  # === Options
  # <tt>:abbreviated</tt> -- If true, returns the summary on an
  # abbreviated format.
  def pos_summary(options = {})
    morph_features.pos_summary(options)
  end

  # Returns the morphological features for the lemma.
  def morph_features
    MorphFeatures.new(self, nil)
  end

  # Lemmata that are 'sufficiently similar' to this lemma to be candidates
  # for being merged with it. 'Sufficiently similar' is defined in terms of
  # what will not violate constraints: two lemmata with different part of
  # speech, for example, cannot be merged since this will affect the
  # annotation of morphology for any associated tokens. Two tokens are
  # 'mergeable' iff they belong to the same language, have the same base
  # form (variant number may be different) and have identical part of
  # speech.
  def mergeable_lemmata
    Lemma.where(:part_of_speech_tag => part_of_speech_tag, :lemma => lemma, :language_tag => language_tag).where("id != ?", id)
  end

  # Tests if lemma can be merged with another lemma +other_lemma+.
  def mergeable?(other_lemma)
    lemma == other_lemma.lemma and language_tag == other_lemma.language_tag and
      part_of_speech_tag == other_lemma.part_of_speech_tag
  end

  # Merges another lemma into this lemma and saves the results. The two lemmata
  # must have the same base form, the same morphology and be for the same language.
  # All tokens belonging to the lemma to be merged will have their lemma references
  # changed, and the lemma without tokens deleted.
  def merge!(other_lemma)
    raise ArgumentError, "Lemmata cannot be merged" unless mergeable?(other_lemma)

    Token.transaction do
      other_lemma.tokens.each do |t|
        t.update_attributes! :lemma_id => self.id
      end
      other_lemma.destroy
    end
  end

  def to_s
    [export_form, part_of_speech.to_s].join(',')
  end

  # Returns an array of all parts of speech represented in lemmata.
  def self.represented_parts_of_speech
    Lemma.uniq.pluck(:part_of_speech_tag).map { |p| PartOfSpeechTag.new(p) }.sort_by(&:to_label)
  end

  def language_name
    LanguageTag.new(language_tag).try(:name)
  end
end
