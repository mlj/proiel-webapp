#!/usr/bin/env ruby
#
# morphtag_constraints.rb - Morphology tag constraints
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'treetop'
require 'singleton'

module PROIEL
  # Definition and test functions for constraints on PROIEL morphtags.
  # This is a singleton class and should be accessed using the
  # +instance+ method.
  class MorphtagConstraints
    include Singleton

    # Regexps for matching certain sets of features in positional tags. 
    BLACK_LIST_REGEXPS = {
      :art =>      /^S/,
      :dual =>     /^...d/,
      :gender =>   /^.......[^-]/,
      :voc =>      /^........v/,
      :abl =>      /^........b/,
      :ins =>      /^........i/,
      :loc =>      /^........l/,
      :aorist =>   /^....a/,
      :optative => /^.....o/,
      :middle =>   /^......[emnd]/,
    }

    # A specification of feature sets that should be treated as invalid
    # in specific languages
    LANGUAGE_BLACK_LISTS = {
      :la =>  [ :art, :dual,                      :ins,       :aorist, :optative, :middle, ],
      :grc => [       :dual,                :abl, :ins, :loc,                              ],
      :hy  => [ :art, :dual, :gender, :voc, :abl, :ins,                :optative, :middle, ],
      :got => [ :art,                 :voc, :abl, :ins, :loc, :aorist, :optative, :middle, ],
      :cu  => [ :art,                       :abl,                      :optative, :middle, ]
    }

    # Tests if a PROIEL morphtag is valid, i.e. that it does not violate
    # any of the constraints in the constraint grammar. If +language+
    # is specified, additional language specific constraints are taken
    # into account.
    def is_valid?(morphtag, language = nil)
      !parse(morphtag, language).nil?
    end

    # Tests if a PROIEL morphtag is complete, i.e. that it includes
    # values for all the fields that are required by the constraint grammar. 
    # If +language+ is specified, additional language specific constraints 
    # are taken into account.
    def is_complete?(morphtag, language = nil)
      m = parse(morphtag, language)
      (m and m.complete?) ? true : false
    end

    private

    def initialize
      Treetop.load File.join(File.dirname(__FILE__), "morphtag_constraints_grammar")
      @parser = PROIEL::MorphtagConstraintsGrammarParser.new
    end

    def parse(morphtag, language = nil)
      if m = @parser.parse(morphtag)
        # Apply language specific black-lists
        if language and LANGUAGE_BLACK_LISTS.has_key?(language.to_sym)
          black_list = LANGUAGE_BLACK_LISTS[language.to_sym]
          return nil if black_list.any? { |b| BLACK_LIST_REGEXPS[b].match(morphtag) }
        end

        m
      else
        nil
      end
    end
  end

  module MorphtagConstraintsGrammar #:nodoc:
    class TerminalCompletionTest < Treetop::Runtime::SyntaxNode
      def complete?
        text_value == '-' ? false : true
      end
    end

    class CompletionTest < Treetop::Runtime::SyntaxNode
      def complete?
        # We are complete if everyone else are
        elements.select { |e| e.respond_to?(:complete?) }.all? { |e| e.complete? }
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

  class MorphtagConstraintsTestCase < Test::Unit::TestCase
    def test_simple
      m = PROIEL::MorphtagConstraints.instance
      assert_equal true, m.is_valid?('V-3sfio----', :la)
      assert_equal true, m.is_complete?('V-3sfio----', :la)

      assert_equal true, m.is_valid?('V----------', :la)
      assert_equal false, m.is_complete?('V----------', :la)

      assert_equal true, m.is_valid?('A--p---fac-', :la)
      assert_equal true, m.is_complete?('A--p---fac-', :la)

      assert_equal true, m.is_valid?('D----------', :cu)
      assert_equal false, m.is_complete?('D----------', :cu)
    end
  end
end
