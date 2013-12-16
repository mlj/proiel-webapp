# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
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
  attr_accessible :lemma, :variant, :gloss, :foreign_ids, :language_tag,
    :part_of_speech_tag

  change_logging

  blankable_attributes :foreign_ids, :gloss

  has_many :tokens
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false
  tag_attribute :part_of_speech, :part_of_speech_tag, PartOfSpeechTag, :allow_nil => false

  validates_presence_of :lemma
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  validates_uniqueness_of :lemma, :scope => [:language_tag, :part_of_speech_tag, :variant]
  validates_numericality_of :variant, allow_nil: true

  # Returns possible completions of a lemma given a language tag and one or
  # more lemma prefixes. +lemma_prefixes+ should be a string or an array of
  # strings. Each string will be treated as a prefix to be matched against
  # lemma base forms in the database. If a variant number is appended to the
  # prefix, e.g.  +foo#1+, +foo+ is treated as a prefix and +1+ as a mandatory
  # variant number. If no variant number is given (or if the variant number is
  # blank), e.g. +foo+, any lemma with the prefix +foo+ will match regardless
  # of whether it has a variant number or not.
  def self.possible_completions(language_tag, lemma_prefixes)
    lemma_prefixes = [*lemma_prefixes]

    statement = lemma_prefixes.map do |query|
      _, variant = query.split('#')
      variant.blank? ? '(lemma LIKE ?)' : '(lemma LIKE ? AND variant = ?)'
    end.join(' OR ')

    terms = lemma_prefixes.map do |query|
      lemma, variant = query.split('#')
      if variant.blank?
        "#{lemma}%"
      else
        ["#{lemma}%", variant]
      end
    end.flatten

    where(language_tag: language_tag).where(statement, *terms)
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

  # Returns lemmata that are sufficiently similar to be candidates for being
  # merged. Two lemmata are sufficiently similar iff they belong to the same
  # language, have the same part of speech tag and have the same base (the
  # variant number, on the other hand, may be different).
  def self.mergeable_lemmata(lemma_form, part_of_speech_tag, language_tag)
    Lemma.where(:part_of_speech_tag => part_of_speech_tag, :lemma => lemma, :language_tag => language_tag)
  end

  # Returns lemmata that are sufficiently similar to be candidates for being
  # merged. Two lemmata are sufficiently similar iff they belong to the same
  # language, have the same part of speech tag and have the same base (the
  # variant number, on the other hand, may be different).
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

  # Returns an array of all parts of speech represented among lemmata. The
  # parts of speech are sorted using +to_label+ as sort key.
  def self.represented_parts_of_speech
    Lemma.uniq.select(:part_of_speech_tag).map(&:part_of_speech).sort_by(&:to_label)
  end

  # Returns an array of all languages represented among lemmata. The languages
  # are sorted using +to_label+ as sort key.
  def self.represented_languages
    Lemma.uniq.select(:language_tag).map(&:language).sort_by(&:to_label)
  end

  def language_name
    LanguageTag.new(language_tag).try(:name)
  end
end
