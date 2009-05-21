#!/usr/bin/env ruby
#
# inflections_table.rb - Morphological tagger: Inflections table method
#
# Written by Marius L. Jøhndal, 2008, 2009.
#
module PROIEL
  module Tagger
    class InflectionsTableMethod < TaggerAnalysisMethod
      def initialize(language)
        super(language)
      end

      def analyze(form)
        language = Language.find_by_iso_code(@language)
        raise "invalid language #{@language}" unless language

        language.inflections.find_all_by_form(form).collect do |instance|
          if instance.manual_rule
            [PROIEL::MorphLemmaTag.new("#{instance.morphtag}:#{instance.lemma}"), 1.0]
          else
            [PROIEL::MorphLemmaTag.new("#{instance.morphtag}:#{instance.lemma}"), 0.2]
          end
        end
      end
    end
  end
end
