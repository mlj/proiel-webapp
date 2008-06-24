#!/usr/bin/env ruby
#
# word_list.rb - Morphological tagger: Word list method
#
# Written by Marius L. Jøhndal, 2008.
#
require 'fastercsv'
require 'gdbm'

module PROIEL
  module Tagger
    class WordListMethod < TaggerAnalysisMethod
      @@open_dbs = {}

      def initialize(language, file_name)
        super(language)

        base_name = File.join(File.dirname(file_name), File.basename(file_name, '.csv'))
        @csv_file_name, @db_file_name = file_name, "#{base_name}.db"

        update_db
      end

      def analyze(form)
        update_db
        access_db(form)
      end

      private

      def access_db(form)
        @@open_dbs[@db_file_name] = GDBM::open(@db_file_name, GDBM::READER) unless @@open_dbs[@db_file_name]
        # FIXME: the READER/WRITER stuff doesn't work at all!
        db = @@open_dbs[@db_file_name]
        begin
          value = db[form]
          values = value ? value.split(',') : []
          y = values.collect { |x| MorphLemmaTag.new(x) }
        ensure
          db.close
          @@open_dbs.delete(@db_file_name)
        end

        y
      end

      def update_db
        csv_mtime = File.mtime(@csv_file_name)
        db_mtime = File.exists?(@db_file_name) ? File.mtime(@db_file_name) : nil
        actually_update_db if db_mtime.nil? or csv_mtime > db_mtime
      end

      def actually_update_db
        # GDBM::NEWDB doesn't seem to really clear the old database properly.
        File.unlink(@db_file_name) if File.exists?(@db_file_name)

        db = GDBM::open(@db_file_name, 0666)

        begin
          FasterCSV.foreach(@csv_file_name, :skip_blanks => true) do |e|
            language, lemma, variant, form, *morphtags = e
            
            raise "Word list database update aborted: invalid language in rule file #{@csv_file_name}" unless language.to_sym == @language
            raise "Word list database Update aborted: invalid morphtag for form #{form} in rule file #{@csv_file_name}" unless morphtags.all? { |m| PROIEL::MorphTag.new(m).is_valid? }

            base_form = variant ? "#{lemma}##{variant}" : lemma
            morphtags.collect! { |m| [PROIEL::MorphTag.new(m).to_s, base_form].join(':') }
            morphtags += db[form].split(',') if db[form]
            db[form] = morphtags.join(',')
          end
        ensure
          db.close
        end
      end
    end
  end
end
