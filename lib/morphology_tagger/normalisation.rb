#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-
#
# normalisation.rb - Language specific orthographic normalisation
# and manipulation
#
# Written by Marius L. Jøhndal, 2007, 2008
#

require 'active_support'
require 'unicode'

module Lingua
  module LAT
    # Normalises the orthography of a word.
    #
    # Reverses «Victorian» orthography, i.e. breaks up the ligatures æ/Æ,
    # œ, and its subsitute ø/Ø, removes trema from ë/Ë, ö/Ö, and changes
    # j/J before vowels to i/I.
    def self.normalise(word, options = {})
      text = word.dup

      text.gsub!(/Æ/, 'Ae')
      text.gsub!(/æ/, 'ae')
      text.gsub!(/Ø/, 'Oe')
      text.gsub!(/[œø]/, 'oe')
      text.gsub!(/Ë/, 'E')
      text.gsub!(/ë/, 'e')
      text.gsub!(/Ö/, 'O')
      text.gsub!(/ö/, 'o')
      text.gsub!(/J([AEIOUYaeiouy])/, 'I\1')
      text.gsub!(/j([aeiouy])/, 'i\1')

      text
    end
  end

  module CU
    # Returns a regular expression that matches all the Unicode characters
    # in the array +characters+.
    def self.make_character_class(characters)
      r = characters.collect { |c| /#{c}/u }
      Regexp.union(*r)
    end

    # Most OCS-Cyrilic diacritics are governed by no uniform usage, so
    # except for presentation of text, it makes little sense to keep them
    # around
    CU_DIACRITICS = ["\u{0485}", "\u{0484}", "\u{0306}", "\u{0308}"].freeze

    # All variants of the letter/sound i. These correspond to different
    # Glagolitic characters, but are distinguished by orthographic
    # considerations that apparently differ between sources. In transcription,
    # these symbols are conflated to `i', in normalised OCS-Cyrilic orthography,
    # и (U+0438/U+0418) is used..
    CU_LOWER_CASE_LETTER_I = ["\u{0438}", "\u{0456}", "\u{A647}"].freeze
    CU_UPPER_CASE_LETTER_I = ["\u{0418}", "\u{0406}", "\u{A646}"].freeze

    # Regexps for all of the above
    CU_DIACRITICS_REGEXP = make_character_class(CU_DIACRITICS).freeze
    CU_LOWER_CASE_LETTER_I_REGEXP = make_character_class(CU_LOWER_CASE_LETTER_I).freeze
    CU_UPPER_CASE_LETTER_I_REGEXP = make_character_class(CU_UPPER_CASE_LETTER_I).freeze

    # Mapping between non-superscripted characters and superscript characters.
    SUPERSCRIPTS = {
      "\u{0431}" => "\u{2de0}", # b
      "\u{0432}" => "\u{2de1}", # v
      "\u{0433}" => "\u{2de2}", # g
      "\u{0434}" => "\u{2de3}", # d
      "\u{a649}" => "\u{2df8}", # g'
      "\u{043b}" => "\u{2de7}", # l
      "\u{043d}" => "\u{2de9}", # n
      "\u{043e}" => "\u{2dea}", # o
      "\u{043f}" => "\u{2deb}", # p
      "\u{0445}" => "\u{2def}", # x
      "\u{0446}" => "\u{2df0}", # c
      "\u{0447}" => "\u{2df1}", # č
      "\u{043a}" => "\u{2de6}", # k
      "\u{0440}" => "\u{2dec}", # r
      "\u{0441}" => "\u{2ded}", # s
      "\u{0442}" => "\u{2dee}", # t
    }.freeze

    # Returns the superscript character that corresponds to a particular
    # character +c+.
    def self.convert_to_superscript(c)
      raise "Character #{c} cannot be converted to superscript" unless SUPERSCRIPTS.has_key?(c)
      SUPERSCRIPTS[c]
    end

    REVERSE_SUPERSCRIPTS = SUPERSCRIPTS.invert.freeze
    SUPERSCRIPT_LETTERS = REVERSE_SUPERSCRIPTS.keys.freeze
    SUPERSCRIPT_LETTERS_REGEXP = make_character_class(SUPERSCRIPT_LETTERS).freeze

    # Normalises the orthography of a word.
    #
    # ==== Options
    # keep_diacritics:: Will not remove diacritics.
    # keep_letter_i_variants:: Will not conflate variant characters for the sound i.
    # no_case_folding:: Will not perform case folding.
    def self.normalise(word, options = {})
      w = word.dup
      w.gsub!(CU_DIACRITICS_REGEXP, '') unless options[:keep_diacritics]
      unless options[:keep_letter_i_variants]
        w.gsub!(CU_LOWER_CASE_LETTER_I_REGEXP, "\u{0438}")
        w.gsub!(CU_UPPER_CASE_LETTER_I_REGEXP, "\u{0418}")
      end
      w.gsub!(SUPERSCRIPT_LETTERS_REGEXP) { |c| REVERSE_SUPERSCRIPTS[$&] }
      options[:no_case_folding] ? w : Unicode::downcase(w)
    end
  end

  module GRC
    private

    U_ACUTE      = "\u{0301}"
    U_GRAVE      = "\u{0300}"
    U_CIRCUMFLEX = "\u{0342}"

    FINAL_ACUTE_REGEXP = Regexp.new("#{U_ACUTE}$").freeze
    ACUTE_REGEXP = Regexp.new(U_ACUTE).freeze
    ACCENTS_REGEXP = Regexp.union(U_ACUTE, U_GRAVE, U_CIRCUMFLEX).freeze

    public

    # Changes an acute to a grave in a string +s+. Returns the
    # new string on Normalisation form C.
    #
    # ==== Options
    # final_only: Only changes a final vowel with an acute.
    def self.acute_to_grave(s, options = {})
      if options[:final_only]
        s.mb_chars.decompose.sub(FINAL_ACUTE_REGEXP, U_GRAVE).mb_chars.normalize
      else
        s.mb_chars.decompose.sub(ACUTE_REGEXP, U_GRAVE).mb_chars.normalize
      end
    end

    # Removes all accents from a string +s+. Returns the new
    # string on Normalisation form C.
    def self.strip_accents(s)
      s.mb_chars.decompose.sub(ACCENTS_REGEXP, '').mb_chars.normalize
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  class LatTestCase < Test::Unit::TestCase
    def test_normalisation
      assert_equal 'aequalia', Lingua::LAT::normalise('æqualia')
      assert_equal 'coepit', Lingua::LAT::normalise('cœpit')
      assert_equal 'Israel', Lingua::LAT::normalise('Israël')
      assert_equal 'Iesus', Lingua::LAT::normalise('Jesus')
      assert_equal 'eiusmodi', Lingua::LAT::normalise('ejusmodi')
    end
  end

  class GrcTestCase < Test::Unit::TestCase
    def test_acute_to_grave
      assert_equal 'μηδὲ', Lingua::GRC::acute_to_grave('μηδέ')
      assert_equal 'μηδὲ', Lingua::GRC::acute_to_grave('μηδέ', :final_only => true)
      assert_equal 'μηδὲ', Lingua::GRC::acute_to_grave('μηδέ', :final_only => false)

      assert_equal 'αὐτοὺς', Lingua::GRC::acute_to_grave('αὐτούς')
      assert_equal 'αὐτούς', Lingua::GRC::acute_to_grave('αὐτούς', :final_only => true)
      assert_equal 'σὐτοὺς', Lingua::GRC::acute_to_grave('σὐτούς', :final_only => false)
    end

    def test_strip_accents
      assert_equal 'μηδε', Lingua::GRC::strip_accents('μηδέ')
      assert_equal 'αὐτους', Lingua::GRC::strip_accents('αὐτοὺς')
      assert_equal 'αὐτοις', Lingua::GRC::strip_accents('αὐτοῖς')
    end
  end
end
