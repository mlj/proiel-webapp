#!/usr/bin/env ruby
#
# instance_frequency.rb - Morphological tagger: Instance frequency method
#
# Written by Marius L. Jøhndal, 2008.
#
module PROIEL
  module Tagger
    class InstanceFrequencyMethod < TaggerAnalysisMethod
      def initialize(language)
        super(language)
      end

      def analyze(form)
        instances = grab_data(form)

        # Filter out those that fail validation or lack a lemma.
        instances.reject! { |tag, lemma, frequency| not PROIEL::MorphTag.new(tag).is_valid?(@language) or lemma.nil? }

        # Compute frequency
        sum = instances.inject(0) { |sum, instance| sum + instance[2] }
        instances.collect do |tag, lemma, frequency|
          [PROIEL::MorphLemmaTag.new("#{tag}:#{lemma}"), frequency / sum.to_f]
        end
      end

      private

      def grab_data(form)
        source = Source.find_by_language(@language)
        result = Token.connection.select_all("SELECT morphtag, lemmata.lemma, lemmata.variant, count(*) AS frequency FROM tokens LEFT JOIN sentences ON sentence_id = sentences.id LEFT JOIN lemmata ON lemma_id = lemmata.id WHERE form = \"#{form}\" AND source_id = #{source.id} AND reviewed_by IS NOT NULL GROUP BY morphtag, lemma_id", 'Token')
        result.collect! do |e|
          [e["morphtag"], e["lemma"] ? (e["variant"] ? [e["lemma"], e["variant"]].join('#') : e["lemma"]) : nil, e["frequency"].to_i]
        end

        result
      end
    end
  end
end
