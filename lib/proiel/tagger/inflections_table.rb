#!/usr/bin/env ruby
#
# inflections_table.rb - Morphological tagger: Inflections table method
#
# Written by Marius L. Jøhndal, 2008, 2009.
#
module Tagger
  class InflectionsTableMethod < TaggerAnalysisMethod
    def initialize(language)
      super(language)
    end

    def analyze(form)
      Inflection.where(language_tag: @language.to_s, form: form).map do |instance|
        [instance.morph_features, instance.manual_rule ? 1.0 : 0.2]
      end
    end
  end
end
