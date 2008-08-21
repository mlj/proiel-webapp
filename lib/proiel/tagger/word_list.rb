#!/usr/bin/env ruby
#
# word_list.rb - Morphological tagger: Word list method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'gdbm'

module PROIEL
  module Tagger
    class WordListMethod < TaggerAnalysisMethod
      @@open_dbs = {}

      def initialize(language, file_name)
        super(language)

        @file_name = file_name
      end

      def analyze(form)
        @@open_dbs[@file_name] = GDBM::open(@file_name, GDBM::READER) unless @@open_dbs[@file_name]
        raise "Error opening word list #{@file_name}" unless @@open_dbs[@file_name]
        (@@open_dbs[@file_name][form] || '').split(',').map { |x| MorphLemmaTag.new(x) }
      end
    end
  end
end
