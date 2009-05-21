# Model for a lemma. Each lemma has a base (non-inflected) form, a language code
# and may additionally be differentiated from other lemmata in the same language
# with the same base form using a integer variant identifier.
class Lemma < ActiveRecord::Base
  has_many :tokens
  has_many :dictionary_references
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy
  belongs_to :language
  belongs_to :part_of_speech

  before_validation :before_validation_cleanup

  searchable_on :lemma

  named_scope :by_variant, lambda { |variant| { :conditions => { :variant => variant } } }

  validates_presence_of :lemma
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  validates_presence_of :part_of_speech

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

  # Merges another lemma into this lemma and saves the results. The two lemmata
  # must have the same base form, the same morphology and be for the same language.
  # All tokens belonging to the lemma to be merged will have their lemma references
  # changed.
  def merge!(other_lemma)
    raise "Different base forms" unless self.lemma == other_lemma.lemma
    raise "Different languages" unless self.language == other_lemma.language
    raise "Different morphology" unless self.pos == other_lemma.pos

    Token.transaction do
      other_lemma.tokens.each do |t|
        t.lemma_id = self.id
        t.save!
      end
    end
  end

  protected

  def self.search(query, options = {})
    options[:order] ||= 'language_id ASC, sort_key ASC, lemma ASC, variant ASC, part_of_speech_id ASC'

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

  # Returns lemmata that are possible completions of the lemma +q+ in the language
  # +language+. The lemma should be given on presentation form, i.e. "lemma" or
  # "lemma#variant". If no variant is given, both completion with and without
  # variant numbers will be returned.
  def self.find_completions(q, language)
    lemma, variant = q.split(/#/)
    unless variant.blank?
      Lemma.find(:all, :include => :language,
                 :conditions => ["languages.iso_code = ? AND lemma LIKE ? AND variant = ?", language, "#{lemma}%", variant])
    else
      Lemma.find(:all, :include => :language,
                 :conditions => ["languages.iso_code = ? AND lemma LIKE ?", language, "#{lemma}%"])
    end
  end

  private

  def before_validation_cleanup
    self.variant = nil if variant.blank?
    self.short_gloss = nil if short_gloss.blank?
    self.foreign_ids = nil if foreign_ids.blank?
  end
end
