#!/usr/bin/env ruby
#
# normalisation.rb - Language specific orthographic normalisation
#
# Written by Marius L. Jøhndal, 2007, 2008
#
require 'unicode'
require 'ucodes'

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
      text.gsub!(/Ø/, 'oe')
      text.gsub!(/[œø]/, 'oe')
      text.gsub!(/Ë/, 'E')
      text.gsub!(/ë/, 'e')
      text.gsub!(/Ö/, 'O')
      text.gsub!(/ö/, 'o')
      text.gsub!(/J([Aeiouyaeiouy])/, 'I\1')
      text.gsub!(/j([Aeiouyaeiouy])/, 'i\1')

      text
    end
  end

  module CU
    # Most OCS-Cyrilic diacritics are governed by no uniform usage, so
    # except for presentation of text, it makes little sense to keep them
    # around
    CU_DIACRITICS = [ Unicode::U0485, Unicode::U0484, Unicode::U0306,
      Unicode::U0308, ].freeze

    # All variants of the letter/sound i. These correspond to different
    # Glagolitic characters, but are distinguished by orthographic
    # considerations that apparently differ between sources. In transcription,
    # these symbols are conflated to `i', in normalised OCS-Cyrilic orthography,
    # и (U+0438/U+0418) is used..
    CU_LOWER_CASE_LETTER_I = [ Unicode::U0438, Unicode::U0456, Unicode::UA647 ].freeze
    CU_UPPER_CASE_LETTER_I = [ Unicode::U0418, Unicode::U0406, Unicode::UA646 ].freeze

    # Regexps for all of the above
    CU_DIACRITICS_REGEXP = Unicode::make_character_class(CU_DIACRITICS).freeze
    CU_LOWER_CASE_LETTER_I_REGEXP = Unicode::make_character_class(CU_LOWER_CASE_LETTER_I).freeze
    CU_UPPER_CASE_LETTER_I_REGEXP = Unicode::make_character_class(CU_UPPER_CASE_LETTER_I).freeze

    # Mapping between non-superscripted characters and superscript characters.
    SUPERSCRIPTS = {
      Unicode::U0431 => Unicode::U2de0, # b
      Unicode::U0432 => Unicode::U2de1, # v
      Unicode::U0433 => Unicode::U2de2, # g
      Unicode::U0434 => Unicode::U2de3, # d
      Unicode::Ua649 => Unicode::U2df8, # g'
      Unicode::U043b => Unicode::U2de7, # l
      Unicode::U043d => Unicode::U2de9, # n
      Unicode::U043e => Unicode::U2dea, # o
      Unicode::U043f => Unicode::U2deb, # p
      Unicode::U0445 => Unicode::U2def, # x
      Unicode::U0446 => Unicode::U2df0, # c
      Unicode::U0447 => Unicode::U2df1, # č
      Unicode::U043a => Unicode::U2de6, # k
      Unicode::U0440 => Unicode::U2dec, # r
      Unicode::U0441 => Unicode::U2ded, # s
      Unicode::U0442 => Unicode::U2dee, # t
    }.freeze

    # Returns the superscript character that corresponds to a particular
    # character +c+.
    def self.convert_to_superscript(c)
      raise "Character #{c} cannot be converted to superscript" unless SUPERSCRIPTS.has_key?(c)
      SUPERSCRIPTS[c]
    end

    REVERSE_SUPERSCRIPTS = SUPERSCRIPTS.invert.freeze
    SUPERSCRIPT_LETTERS = REVERSE_SUPERSCRIPTS.keys.freeze
    SUPERSCRIPT_LETTERS_REGEXP = Unicode::make_character_class(SUPERSCRIPT_LETTERS).freeze

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
        w.gsub!(CU_LOWER_CASE_LETTER_I_REGEXP, Unicode::U0438)
        w.gsub!(CU_UPPER_CASE_LETTER_I_REGEXP, Unicode::U0418)
      end
      w.gsub!(SUPERSCRIPT_LETTERS_REGEXP) { |c| REVERSE_SUPERSCRIPTS[$&] }
      options[:no_case_folding] ? w : Unicode::downcase(w)
    end
  end
end
