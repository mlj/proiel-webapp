#!/usr/bin/env ruby
#
# analysis_method.rb - Morphological tagger: Abstract analysis method
#
# Written by Marius L. Jøhndal, 2008.
#
module Tagger
  class TaggerAnalysisMethod
    def initialize(language)
      @language = language
    end

    def analyze(form)
      []
    end
  end
end
