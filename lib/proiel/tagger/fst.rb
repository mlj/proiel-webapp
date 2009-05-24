#!/usr/bin/env ruby
#
# fst.rb - Morphological tagger: FST method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'proiel/tagger/analysis_method'
require 'sfst_interface'

module Tagger
  class FSTMethod < TaggerAnalysisMethod
    def initialize(language, analysis, normalisation = nil, orthography = nil)
      super(language)

      @analyzer = SFSTAnalyzer.new(language, analysis, normalisation, orthography)
    end

    def analyze(form)
      @analyzer.analyze(form)
    end
  end
end
