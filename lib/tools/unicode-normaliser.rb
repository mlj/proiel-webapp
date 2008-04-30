#!/usr/bin/env ruby
#
# unicode-normalisation - Normalise Unicode strings in database
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
require 'unicode'

module PROIEL
  module Tools
    class UnicodeNormaliser
      def initialize(args)
        raise "Invalid arguments" unless args.length != 0
      end

      def audited?
        false
      end

      def run!(logger, job)
        Source.find(:all).each do |source|
          n = 0
          logger.info { "Working on source #{source.code}..." }

          source.sentences.each do |sentence|
            sentence.tokens.each do |token|
              next if token.form.nil?

              normalisation = Unicode::normalize_C(token.form)
              if normalisation != token.form
                token.form = normalisation
                token.save_without_auditing
                n += 1
              end
            end
          end

          logger.info { "#{n} changes in source #{source.id}..." }
        end

        n = 0
        logger.info { "Working on lemmata..." }

        Lemma.find(:all).each do |lemma|
          normalisation = Unicode::normalize_C(lemma.lemma)
          if normalisation != lemma.lemma 
            lemma.lemma = normalisation
            lemma.save
            n += 1
          end
        end

        logger.info { "#{n} changes in lemmata..." }
      end
    end
  end
end
