#--
#
# Copyright 2007, 2008, 2009, 2010 University of Oslo
# Copyright 2007, 2008, 2009, 2010 Marius L. Jøhndal
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
class Inflection < ActiveRecord::Base
  composed_of :language, :converter => Proc.new { |value| value.is_a?(String) ? Language.new(value) : value }
  validates_presence_of :language
  validates_presence_of :form
  validates_presence_of :morphology
  validates_length_of :morphology, :is => MorphFeatures::MORPHOLOGY_LENGTH
  composed_of :morphology, :allow_nil => true, :converter => Proc.new { |value| value.is_a?(String) ? Morphology.new(value) : value }
  validates_presence_of :lemma

  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  # FIXME: validate morphology vs language?
  #validates_inclusion_of :morphology, :in => MorphFeatures.morphology_tag_space(language.tag)
  # FIXME: broken for language and part_of_speech, which are YAMLified
  # because of +ActiveRecord::ConnectionAdapters::Quoting#quote+.
  validates_uniqueness_of :form, :scope => [:language, :morphology, :lemma]

  # Returns the morphological features. These will never be nil.
  def morph_features
    MorphFeatures.new([lemma, language.tag].join(','), morphology.tag)
  end
end
