#!/usr/bin/env ruby
#
# aligner.rb - Sentence aligner
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
require 'proiel'
require 'jobs'
require 'lingua'

module PROIEL
  module Tools
    class Aligner 
      def initialize(args)
        unless args.length == 1 
          raise "Usage: source_identifier"
        end
          
        @source_identifier = args.first
      end

      def source
        @source_identifier 
      end

      def audited?
        false
      end

      def run!(logger, job)
        source = job.source
        target_source = job.source.aligned_with

        logger.info { "Aligning #{source.code} with #{target_source.code}" } 

        book_id = 2
        for chapter in 1..10
        a = source.sentences.find(:all, :conditions => [ 'book_id = ? and chapter = ?', book_id, chapter ], :order => 'sentence_number')
        b = target_source.sentences.find(:all, :conditions => [ 'book_id = ? and chapter = ?', book_id, chapter ], :order => 'sentence_number')

        align_sentences(a, b)
        end
      end

      private

      def get_hard_region(sentences)
        sentences.collect { |x| { :id => x.id, :data => x.tokens.collect(&:form).compact }}
      end

      def align_sentences(sentences1, sentences2)
        x, y = Alignment::align_regions([get_hard_region(sentences1)], 
                                        [get_hard_region(sentences2)], Alignment::CHARACTER_LENGTH_METRIC)

        # Alignment map
        x.each_index do |i|
          puts "#{x[i].inspect} <-> #{y[i].inspect}" 
        end

        # Anchors
        x.each_index do |i|
          SentenceAlignment.create!(:primary_sentence_id => x[i].first,
                                    :secondary_sentence_id => y[i].first,
                                    :confidence => 1.0) #TODO:fix confidences
        end
      end
    end
  end
end
