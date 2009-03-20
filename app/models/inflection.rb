class Inflection < ActiveRecord::Base
  belongs_to :language

  validates_presence_of :language
  validates_presence_of :form
  validates_presence_of :morphtag
  validates_presence_of :lemma

  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  validates_length_of :morphtag, :is => PROIEL::MorphTag.fields.length
  #FIXME
  #validates_inclusion_of :morphtag, :in => PROIEL::MorphTag.tag_space(language.iso_code)
  validates_uniqueness_of :form, :scope => [:language_id, :morphtag, :lemma]
end
