#--
#
# Copyright 2007, 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
# Model for a lemma. Each lemma has a base (non-inflected) form, a language code
# and may additionally be differentiated from other lemmata in the same language
# with the same base form using a integer variant identifier.
class Lemma < ActiveRecord::Base
  has_many :tokens
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy
  composed_of :language, :converter => Proc.new { |value| value.is_a?(String) ? Language.new(value) : value }
  composed_of :part_of_speech, :converter => Proc.new { |value| value.is_a?(String) ? PartOfSpeech.new(value) : value }, :allow_nil => true

  before_validation :before_validation_cleanup

  searchable_on :lemma

  # Limits the scope to a language.
  named_scope :by_language, lambda { |language| { :conditions => { :language => language }}}

  # Limits the scope to a variant.
  named_scope :by_variant, lambda { |variant| { :conditions => { :variant => variant }}}

  # Limits the scope to potential completions of +queries+. +queries+
  # should be an array of strings on the form +foo+ or +foo#1+, where
  # +foo+ is a prefix of all lemmata to be returned, and +1+ is a
  # variant number required to be present.
  named_scope :by_completions, lambda { |language_code, queries| { :conditions => build_completion_terms(language_code, queries) } }

  validates_presence_of :lemma
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  validates_presence_of :part_of_speech
  validates_inclusion_of :part_of_speech, :in => PartOfSpeech.all, :message => "%{value} is not a valid part of speech"
  # FIXME: broken for language and part_of_speech, which are YAMLified
  # because of +ActiveRecord::ConnectionAdapters::Quoting#quote+.
  validates_uniqueness_of :lemma, :scope => [:language, :part_of_speech, :variant]

  acts_as_audited

  # Returns the export-form of the lemma.
  def export_form
    self.variant ? "#{self.lemma}##{self.variant}" : self.lemma
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

  # Returns a list of lemmata that are 'sufficiently similar' to this
  # lemma to be candidates for being merged with it. 'Sufficiently
  # similar' is defined in terms of what will not violate constraints:
  # two lemmata with different part of speech, for example, cannot be
  # merged since this will affect the annotation of morphology for any
  # associated tokens. Two tokens are 'mergable' iff they belong to
  # the same language, have the same base form (variant number may be
  # different) and have identical part of speech.
  def mergeable_lemmata
    Lemma.find(:all, :conditions => { :part_of_speech => part_of_speech.tag, :lemma => lemma, :language => language.to_s }) - [self]
  end

  # Tests if lemma can be merged with another lemma +other_lemma+.
  def mergable?(other_lemma)
    self.lemma == other_lemma.lemma and
      self.language == other_lemma.language and
      self.part_of_speech == other_lemma.part_of_speech
  end

  # Merges another lemma into this lemma and saves the results. The two lemmata
  # must have the same base form, the same morphology and be for the same language.
  # All tokens belonging to the lemma to be merged will have their lemma references
  # changed, and the lemma without tokens deleted.
  def merge!(other_lemma)
    raise ArgumentError, "Lemmata cannot be merged" unless mergable?(other_lemma)

    Token.transaction do
      other_lemma.tokens.each do |t|
        t.lemma_id = self.id
        t.save!
      end
      other_lemma.destroy
    end
  end

  protected

  def self.search(query, options = {})
    options[:order] ||= 'language ASC, sort_key ASC, lemma ASC, variant ASC, part_of_speech ASC'

    if query.blank?
      paginate options
    else
      lemma, variant = query.split('#')
      if variant
        by_variant(variant).search_on(lemma).paginate options
      else
        search_on(lemma).paginate options
      end
    end
  end

  private

  # Returns conditions for a completion query.
  def self.build_completion_terms(language_code, queries)
    q = queries.map { |query| query.split('#') }

    statement = q.map do |lemma, variant|
      variant.blank? ? 'lemma LIKE ?' : 'lemma LIKE ? AND variant = ?'
    end.map { |s| "(language = '#{language_code}' AND #{s})" }.join(' OR ')

    terms = q.map do |lemma, variant|
      if variant.blank?
        "#{lemma}%"
      else
        ["#{lemma}%", variant]
      end
    end.flatten

    [statement] + terms
  end

  def before_validation_cleanup
    self.variant = nil if variant.blank?
    self.short_gloss = nil if short_gloss.blank?
    self.foreign_ids = nil if foreign_ids.blank?
  end

  public

  def to_s
    [export_form, part_of_speech.to_s].join(',')
  end
end
