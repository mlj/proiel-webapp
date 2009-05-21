#!/usr/bin/env ruby
#
# word_list.rb - Morphological tagger: Word list method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'pstore'

module Tagger
    class WordListMethod < TaggerAnalysisMethod
      def initialize(language, file_name)
        super(language)

        @file_name = file_name
        raise "Error word list #{file_name} not found" unless File.exists?(@file_name)

        @db = PStore.new(file_name)
        raise "Error opening word list #{file_name}" unless @db
      end

      def analyze(form)
        @db.transaction(true) do
          @db.fetch(form.to_s, []).map do |x|
            morphtag, lemma = x.split(':')
            MorphFeatures.new([lemma, morphtag[0, 2], @language.to_s].join(','), morphtag[2, 11])
          end
        end
      end
    end
end
