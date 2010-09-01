class Inflection < ActiveRecord::Base
  belongs_to :language
  belongs_to :morphology

  validates_presence_of :language
  validates_presence_of :form
  validates_presence_of :morphology
  validates_presence_of :lemma

  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  # FIXME: validate morphology vs language?
  #validates_inclusion_of :morphology, :in => MorphFeatures.morphology_tag_space(language.tag)
  validates_uniqueness_of :form, :scope => [:language_id, :morphology_id, :lemma]

  # Returns the morphological features. These will never be nil.
  def morph_features
    MorphFeatures.new([lemma, language].join(','), morphology.tag)
  end
end
