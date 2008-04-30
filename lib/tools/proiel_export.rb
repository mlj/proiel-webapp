#!/usr/bin/env ruby
#
# proiel_export.rb - PROIEL database export
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
require 'proiel'
require 'jobs'

module PROIEL
  module Tools
    class PROIELExport 
      def initialize(args)
        unless args.length >= 2 
          raise "Usage: [--without-morphology] [--without-dependencies] [--reviewed-only] source_identifier destination_file"
        end

        @include = {
          :morphology => true,
          :dependencies => true,
          :reviewed_only => false,
        }

        while args.length > 2
          case args.first
          when '--without-morphtags'
            @include[:morphology] = false
            args.shift
          when '--without-dependencies'
            @include[:dependencies] = false
            args.shift
          when '--reviewed-only'
            @include[:reviewed_only] = true 
            args.shift
          end
        end
          
        @source_identifier, @outfile = args
      end

      def source
        @source_identifier 
      end

      def audited?
        false
      end

      def run!(logger, job)
        source = job.source
        include = @include

        PROIEL::Writer.new(@outfile, source.code, source.language, {
          :title => source.title,
          :edition => source.edition,
          :source => source.source,
          :editor => source.editor,
          :url => source.url,
        }) do
          ss = include[:reviewed_only] ? source.reviewed_sentences : source.sentences
          ss.each do |sentence|
            sentence.tokens.each do |token|
              # Skip empty nodes unless we include dependencies
              next if token.empty? and not include[:dependencies]

              track_references(sentence.book.code, sentence.chapter, token.verse)

              attributes = {}

              if include[:dependencies]
                attributes[:id] = token.id
                attributes[:relation] = token.relation if token.relation
                attributes[:head] = token.head_id if token.head
              end

              if include[:morphology]
                attributes[:morphtag] = token.morphtag if token.morphtag
                attributes[:lemma] = token.lemma.presentation_form if token.lemma
              end

              attributes[:sort] = token.sort.to_s.gsub(/_/, '-')
              attributes['composed-form'] = token.composed_form if token.composed_form

              emit_word(token.form, attributes)
            end
            next_sentence
          end
        end
      end
    end
  end
end
