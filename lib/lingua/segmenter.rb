#!/usr/bin/env ruby
#
# segmenter.rb - Segmentation
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: $
#
require 'yaml'
require 'unicode'
require 'oniguruma'
include Oniguruma

module Lingua
  DATADIR = File.expand_path(File.dirname(__FILE__))

  class Segmenter
    DEFINITIONS = YAML::load_file(File.join(DATADIR, 'segmenter.yml'))

    def self.has_language?(language)
      DEFINITIONS.has_key?(language.to_sym)
    end

    def initialize(language, options = {})
      @definitions = DEFINITIONS[language]
      
      @language = language
      
      @contractions = @definitions[:contractions] || {}

      @bound_morphemes = @definitions[:bound_morphemes] || {}
      @bound_morpheme_patterns = @bound_morphemes.collect { |key, value| Regexp.new("(?:.)(#{key})$") } 
      @all_punctuation = []
      @all_punctuation += @definitions[:nonspacing_punctuation] if @definitions[:nonspacing_punctuation]
      @all_punctuation += @definitions[:spacing_punctuation] if @definitions[:spacing_punctuation] 
      @all_punctuation += @definitions[:left_bracketing_punctuation] if @definitions[:left_bracketing_punctuation]
      @all_punctuation += @definitions[:right_bracketing_punctuation] if @definitions[:right_bracketing_punctuation]

      # Why is there no ORegexp.union?
      nsp = ORegexp.escape(@definitions.fetch(:nonspacing_punctuation, []).join)
      ssp = @definitions.fetch(:spacing_punctuation, [])
      lbr = ORegexp.escape(@definitions.fetch(:left_bracketing_punctuation, []).join)
      rbr = ORegexp.escape(@definitions.fetch(:right_bracketing_punctuation, []).join)

      nsp = "[#{nsp}]" unless nsp == ''
      lbr = "[#{lbr}]" unless lbr == ''
      rbr = "[#{rbr}]" unless rbr == ''

      @punctuation_pattern = ORegexp.new("^(#{lbr})?(.*?)(#{rbr})?(#{nsp})?$", 'i', 'utf8')

      @spacing_punctuation_pattern = ssp
    end

    # Returns +true+ if segmenter considers the given string +s+
    # as punctuation.
    def is_punctuation?(s)
      @all_punctuation.include?(s)
    end

    def segmenter(chunk)
      chunk.split(' ').each do |word|
        process_word_segment(Unicode.normalize_C(word)).each { |token| yield token }
      end
    end

    private

    def process_word_segment(word_segment)
      if @spacing_punctuation_pattern.include?(word_segment)
        punctuation = word_segment
        r = [{ :form => punctuation, :sort => :punctuation }]
      elsif m = @punctuation_pattern.match(word_segment)
        dummy, lbr, word, rbr, punctuation = m.to_a

        r = []
        r << { :form => lbr, :sort => :punctuation, :nospacing => :after } if lbr and lbr != ''
        r += process_word(word) if word and word != ''
        r << { :form => rbr, :sort => :punctuation, :nospacing => :before } if rbr and rbr != ''
        r << { :form => punctuation, :sort => :punctuation, :nospacing => :before } if punctuation and punctuation != ''
        r
      else
        STDERR.puts "Error matching punctuation pattern"
      end
    end

    def process_word(word)
      # Check for a verbatim match in the list of `contractions'
      if c = @contractions[word]
        host_word, bound_word = c
        
        [{ :form => host_word,  :sort => :text, :contraction => true, :presentation_form => word,
           :presentation_span => 2 },
         { :form => bound_word, :sort => :text }]
      else
        process_uncontracted_word(word)
      end
    end

    def process_uncontracted_word(word) 
      # Look for specific productive word + bound morpheme combinations
      morpheme_match = @bound_morpheme_patterns.find { |pattern| word[pattern] }
      bound = false

      if morpheme_match
        w = word.match(morpheme_match)
        # We can't use pre_match for base here as the non-capturing group matches, even though
        # it doesn't capture.
        base, morpheme = word.slice(0...w.begin(1)), w[1]
        d = @bound_morphemes[morpheme]

        case d[:mode]
        when :all
          unless d[:blacklist][word] or base == ''
            puts "Warning: Treating #{word} as #{base} + #{morpheme}." unless d[:whitelist][word]
            bound = true
          end
        when :whitelist_only
          bound = true if d[:whitelist][word]
        end
      end

      if bound
        [{ :form => base, :sort => :text, :contraction => true, :presentation_form => base + morpheme, :presentation_span => 2 }, 
         { :form => morpheme, :sort => :text }]
      else
        [{ :form => word, :sort => :text }]
      end
    end
  end
end
