#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
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

class Inflection < ActiveRecord::Base
  attr_accessible :lemma, :form, :language_tag, :morphology_tag, :part_of_speech_tag

  tag_attribute :language, :language_tag, LanguageTag, :allow_nil => false

  validates_presence_of :form

  composed_of :morphology, :mapping => %w(morphology_tag to_s), :allow_nil => true, :converter => Proc.new { |x| Morphology.new(x) }
  validates_presence_of :morphology_tag
  validates_length_of :morphology_tag, :is => MorphFeatures::MORPHOLOGY_LENGTH

  validates_presence_of :lemma

  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM
  validates_unicode_normalization_of :lemma, :form => UNICODE_NORMALIZATION_FORM
  validates_uniqueness_of :form, :scope => [:language_tag, :morphology_tag, :lemma, :part_of_speech_tag]

  # Returns the morphological features. These will never be nil.
  def morph_features
    MorphFeatures.new([lemma, part_of_speech_tag, language.tag].join(','), morphology.tag)
  end
end
