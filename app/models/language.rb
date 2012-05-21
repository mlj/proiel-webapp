#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Marius L. Jøhndal
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

class Language
  include Comparable

  attr_reader :tag

  def self.all
    ISOCodes.all_iso_639_3_codes.map { |l| Language.new(l) }.sort_by(&:name)
  end

  def self.find(tag)
    if ISOCodes.find_language(tag)
      Language.new(tag)
    else
      nil
    end
  end

  def initialize(tag)
    raise ArgumentError, "invalid language code" if ISOCodes.find_language(tag).blank?
    @tag = tag
  end

  # Returns the language code as a string. Equivalent to
  # +language.tag+.
  def to_s
    tag
  end

  def language
    tag
  end

  def name
    # Successful lookup is verified in constructor.
    ISOCodes.find_language(tag).reference_name
  end

  # Returns inferred morphology for a word form in the language.
  #
  # ==== Options
  # <tt>:ignore_instances</tt> -- If set, ignores all instance matches.
  # <tt>:force_method</tt> -- If set, forces the tagger to use a specific tagging method,
  #                          e.g. <tt>:manual_rules</tt> for manual rules. All other
  #                          methods are disabled.
  def guess_morphology(form, existing_tags, options = {})
    TAGGER.tag_token(tag.to_sym, form, existing_tags)
  rescue Exception => e
    Rails.logger.error { "Tagger failed: #{e}" }
    [:failed, nil]
  end

  # Returns a transliterator for the language or +nil+ if none exists.
  def transliterator
    t = TRANSLITERATORS[tag.to_sym]
    t ? TransliteratorFactory::get_transliterator(t) : nil
  end

  # Returns potential lemma completions based on query string on the
  # form +foo+ or +foo#1+. +foo+ should be the prefix of the lemmata
  # to be returned and may be transliterated. The result is returned
  # as two arrays: one with the transliterations of the query and one
  # with completions.
  def self.find_lemma_completions(language_code, query)
    language = Language.new(language_code)

    if language
      if t = language.transliterator
        results = t.transliterate_string(query)
        completion_candidates = results
      else
        results = []
        completion_candidates = [query]
      end

      completions = Lemma.where(:language_tag => language_code).by_completions(completion_candidates)

      [results.sort.uniq, completions]
    else
      [[query], []]
    end
  end

  def <=>(x)
    self.tag <=> x.tag
  end

  def errors
    ActiveModel::Errors.new(self)
  end

  def lemmata
    Lemma.where(:language_tag => tag).order('lemma ASC')
  end

  def to_label
    name
  end
end
