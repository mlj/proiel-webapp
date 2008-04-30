#!/usr/bin/env ruby
#
# db_validator.rb - Database validator
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'proiel'
include Lingua
require 'jobs'

module PROIEL
  module Tools
    class DbValidator 
      USAGE = "[--fix]"

      def initialize(args)
        if args.length == 0 
          @fix = false
        elsif args.length == 1
          if args.first == '--fix'
            @fix = true
          else
            raise usage
          end
        else
          raise usage
        end
      end

      def source
        nil
      end

      def audited?
        true
      end

      def run!(logger, job)
        Token.transaction do
          # validate_changesets_and_changes(logger)

          validate_sentences_and_tokens(logger)
          check_lemmata(logger)

          #  check_morphtag_completeness(logger)

          #check_dependency_structure_completeness(logger)
          check_orphaned_tokens(logger)
        end
      end

      private

      def validate_changesets_and_changes(logger)
        logger.info { "Validating changesets and changes..." }

        failures = false

        # Check Audit first so that any fixes that lead to empty audits
        # can be handled by validation of Changeset
        changes = Audit.find(:all)
        changes.each do |change|
          change.errors.each_full { |msg| logger.error { "Audit #{change.id}: #{msg}" } } unless change.valid?

          if @fix
            # Remove changes from "X" to "X"
            if change.action != 'destroy'
              change.changes.each_pair do |key, values|
                old_value, new_value = values
                if old_value == new_value
                  logger.warn { "Audit #{change.id}: Removing redundant diff element #{key}: #{old_value} -> #{new_value}" }
                  change.changes.delete(key)
                  change.save!
                end
              end
            end

            # Remove empty changes
            if change.action != 'destroy' and change.changes.empty?
              others = Audit.find(:all, :conditions => [
                "auditable_type = ? and auditable_id = ? and version > ?",
                change.auditable_type,
                change.auditable_id,
                change.version ])

              if others.length == 0
                logger.warn { "Audit #{change.id}: Removing empty change" }
                change.destroy
              else
                logger.warn { "Audit #{change.id}: Removing empty change and moving version numbers" }
                change.destroy
                others.each do |v|
                  v.decrement!(:version)
                end
              end
            end
          end
        end

        changesets = Changeset.find(:all)
        changesets.each do |changeset|
          changeset.errors.each_full { |msg| logger.error { "Changeset #{changeset.id}: #{msg}" } } unless changeset.valid?
          
          if @fix
            if changeset.changes.length == 0
              logger.warn { "Changeset #{changeset.id}: Removing empty changeset" }
              changeset.destroy
            end
          end
        end
      end

      def validate_sentences_and_tokens(logger)
        logger.info { "Validating sentences and tokens..." }
        sentences = Sentence.find(:all, :conditions => [ "annotated_by is not null" ])
        sentences.each do |sentence|
          unless sentence.valid?
            sentence.errors.each_full { |msg| logger.error { "Sentence #{sentence.id}: #{msg}" } }
          end

          sentence.tokens.each do |token|
            unless token.valid?
              token.errors.each_full do |msg|
                logger.error { "Token #{token.id} (#{token.form}/#{token.sort.inspect}): #{msg}" }
              end
            end
          end
        end
      end

      def check_dependency_structure_completeness(logger)
        logger.info { "Checking dependency structure completeness..." }

        sentences = Sentence.find(:all, :conditions => [ "annotated_by is not null"])
        sentences.each do |s|
          complete = s.dependency_tokens.all?(&:relation)
          logger.error { "Sentence #{s.id}: Incomplete dependency structure." } unless complete
        end
      end

      def check_orphaned_tokens(logger)
        logger.info { "Checking for orphaned tokens..." }

        orphans = Token.find(:all, 
                             :include => [ :sentence ], 
                             :conditions => [ "sentences.id is null" ])
        orphans.each { |o| logger.error { "Token #{o.id} is orphaned" } }
      end

      def check_orphaned_lemmata(logger)
      end

      def check_morphtag_completeness(logger)
        logger.info { "Checking morphtag completeness..." }

        sentences = Sentence.find(:all)
        sentences.each do |s|
          s.tokens.each do |t|
            if t.morphtaggable? and not t.morphtag.nil?
              m = MorphTag.new(t.morphtag)

              if m.valid? and not m.complete?
                logger.warn { "Token #{t.id} (#{t.form}): Morphtag is incomplete." }
              end
            end
          end
        end
      end

      def check_lemmata(logger)
        logger.info { "Checking for orphaned lemmata..." }
        orphans = Lemma.find(:all, 
                             :include => [ :tokens ], 
                             :conditions => [ "fixed = 0 and tokens.id is null" ])
        orphans.each do |o| 
          logger.error { "Lemma #{o.id} (#{o.presentation_form}) is orphaned" } 
          o.destroy if @fix
        end

        logger.info { "Checking that each reviewed token has a valid lemma..." }
        bad_ones = Token.find(:all, 
                              :include => [ :sentence ], 
                              :conditions => [ "sort not in ('empty', 'nonspacing_punctuation') and sentences.reviewed_by is not null and lemma_id is null" ])
        bad_ones.each do |o| 
          logger.error { "Token #{o.id} [#{o.sort}]: Reviewed but no lemma (http://logos.uio.no:3000/tokens/#{o.id})" } 
        end

        logger.info { "Checking that lemmata with variant numbers do not also occur without variant numbers..." }
        candidates = Lemma.find(:all, 
                                :conditions => [ "variant is not null" ])
        candidates.each do |o|
          if c = Lemma.find(:first, :conditions => [ "lemma = ? and language = ? and variant is null", o.lemma, o.language ])
            logger.error { "Lemma base form #{o.lemma} occurs both with and without variant numbers" }
          end
        end

        logger.info { "Checking that lemma morphology does not contradict token morphology..." }
      end
    end
  end
end
