#!/usr/bin/env ruby
#
# static_tagger.rb -
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
$KCODE = 'UTF8'
require 'jobs'
require 'proiel'

module PROIEL
  module Tools
    class StaticTagger
      def initialize(args)
        if args.first == '--all'
          @change_all = true
          args.shift
        else
          @change_all = false
        end

        if args.length != 2
          raise "Invalid arguments: [--all] source_identifier word_form"
        end

        @source = args.shift
        @word_form = args.shift
        @expected_sort = :word

        s = Source.find_by_code(@source)
        result, pick, *suggestions = s.invoke_tagger(@word_form, @expected_sort, nil, 
                                                     :ignore_instances => true)

        raise "Tagger cannot determine tag unambiguously: #{result}, #{pick.inspect}, #{suggestions.inspect}" unless result == :unambiguous and !pick.nil? and suggestions.length == 1

        # Determine lemma ID
        l = Lemma.find_all_by_language_and_lemma(s.language, pick.lemma)
        
        if l.length == 0
          raise "Cannot find lemma"
        elsif l.length > 1
          raise "Multiple lemmata match lemma from tagger"
        end

        @ml_tag = pick
        @lemma_id = l.first.id
      end

      def source
        @source
      end

      def audited?
        true
      end

      def run!(logger, job)
        stats = FrequencyTabulation.new 

        Sentence.transaction do
          cond = 'id != -1' #dummy
          cond = "reviewed_by is null" unless @change_all
          job.source.sentences.find(:all, :conditions => cond).each do |s|
            s.morphtaggable_tokens.find(:all, :conditions => [ 'form = ? and morphtag is not null', @word_form ]).each do |t|
              raise "Encountered token with unexpected sort #{t.sort}" unless t.sort == @expected_sort
              unless t.morphtag == @ml_tag.morphtag.to_s and t.lemma_id == @lemma_id
                stats.inc(t.morph_lemma_tag)
  
                t.morphtag = @ml_tag.morphtag.to_s
                t.lemma_id = @lemma_id 
                t.save!
              end
            end
          end
        end

        stats.each_pair do |ml_tag, frequency|
          logger.info { "#{ml_tag} -> #{@ml_tag}: #{frequency}" }
        end
      end
    end
  end
end
