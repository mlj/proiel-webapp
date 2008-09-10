#!/usr/bin/env ruby
#
# word_list.rb - Morphological tagger: Word list method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'pstore'

module PROIEL
  module Tagger
    class WordListMethod < TaggerAnalysisMethod
      def initialize(language, file_name)
        super(language)

        @file_name = file_name
        @db = PStore.new(file_name)
        raise "Error opening word list #{file_name}" unless @db
      end

      def analyze(form)
        @db.transaction(true) do
          @db.fetch(form.to_s, []).map { |x| MorphLemmaTag.new(x) }
        end
      end
    end
  end
end
