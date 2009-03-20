#!/usr/bin/env ruby
#
# morphtag_constraints.rb - Morphology tag constraints
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'singleton'
require 'sfst'

module PROIEL
  # Definition and test functions for constraints on PROIEL morphtags.
  # This is a singleton class and should be accessed using the
  # +instance+ method.
  class MorphtagConstraints
    include Singleton

    # Regexps for matching certain sets of features in positional tags. 
    BLACK_LIST_REGEXPS = {
      :art =>           /^S/,
      :dual =>          /^...d/,
      :voc =>           /^........v/,
      :abl =>           /^........b/,
      :ins =>           /^........i/,
      :loc =>           /^........l/,
      :gen_dat =>       /^........c/,
      :resultative =>   /^....s/,
      :past =>          /^....u/,
      :aorist =>        /^....a/,
      :optative =>      /^.....o/,
      :middle =>        /^......[emnd]/,
      :perfect =>       /^....r/,
      :pluperfect =>    /^....l/,
      :futperfect =>    /^....t/,

      :fut_inf =>       /^....fn/,
      :past_part =>     /^....up/,
      :aorist_imp =>    /^....am/,
      :fut_imp =>       /^....fm/,
      :perf_imp =>      /^....rm/,
    }

    # A specification of feature sets that should be treated as invalid
    # in specific languages
    LANGUAGE_BLACK_LISTS = {
      :lat => [ :art, :dual,             :ins, :loc, :aorist, :resultative, :past,             :optative, :middle, :gen_dat, :fut_inf,                                     :aorist_imp,           :perf_imp, ],
      :grc => [       :dual,       :abl, :ins, :loc,          :resultative, :past,                                 :gen_dat,                                                            :fut_imp,            ],
      :xcl => [ :art, :dual, :voc, :abl, :ins,                :resultative, :past,             :optative, :middle, :gen_dat, :fut_inf,                                                  :fut_imp, :perf_imp, ],
      :got => [ :art,              :abl, :ins, :loc, :aorist, :resultative,        :past_part,            :middle, :gen_dat, :fut_inf,                                     :aorist_imp, :fut_imp, :perf_imp, ],
      :chu => [ :art,              :abl,                                                       :optative, :middle,           :fut_inf, :pluperfect, :futperfect, :perfect, :aorist_imp, :fut_imp, :perf_imp, ],
    }

    private

    def initialize
      @fst = SFST::RegularTransducer.new(File.join(File.dirname(__FILE__), "morphtag_constraints.a"))
      @tag_spaces = {}
    end

    def make_tag_space(language)
      tags = []
      @fst.generate_language(:levels => :upper) do |t|
        lang, *others = t
        next unless lang == "<#{language.to_s.upcase}>"
        t = others.join

        tags << t if is_valid_in_language?(t, language)
      end
      tags.uniq
    end

    def is_valid_in_language?(tag, language)
      black_list = LANGUAGE_BLACK_LISTS[language]

      if black_list and black_list.any? { |b| BLACK_LIST_REGEXPS[b].match(tag) }
        false
      else
        true
      end
    end

    public

    def tag_space(language)
      language = language.to_sym
      @tag_spaces[language] ||= make_tag_space(language)
    end

    # Tests if a PROIEL morphtag is valid, i.e. that it does not violate
    # any of the specified constraints.
    def is_valid?(morphtag, language)
      language = language.to_sym
      t = "<#{language.to_s.upcase}>" + morphtag
      if @fst.accepted_analysis?(t)
        return is_valid_in_language?(morphtag, language) if language
        true
      else
        false
      end
    end

    def to_features(morphtag)
      s = @fst.analyze(morphtag)
      raise "Multiple analyses" if s.length > 0
    end
  end
end
