#!/usr/bin/env ruby
#
# instance_frequency.rb - Morphological tagger: Instance frequency method
#
# Written by Marius L. Jøhndal, 2008.
#
module Tagger
  class InstanceFrequencyMethod < TaggerAnalysisMethod
    def initialize(language)
      super(language)
    end

    def analyze(form)
      language = Language.find_by_iso_code(@language.to_s)

      x = Token.connection.select_all("SELECT tokens.id AS token_id, count(*) AS frequency FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id LEFT JOIN lemmata ON lemma_id = lemmata.id WHERE form = \"#{form}\" AND lemmata.language_id = #{language.id} AND reviewed_by IS NOT NULL GROUP BY morphology_id, lemma_id", 'Token')
      sum = x.map { |i| i["frequency"].to_i }.sum.to_f
      x.map { |i| [Token.find(i["token_id"]).morph_features, i["frequency"].to_i / sum] }
    end
  end
end
