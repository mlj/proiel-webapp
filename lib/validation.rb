#!/usr/bin/env ruby
#
# validation.rb - Extra (i.e. non-model) data validation
#
# Written by Marius L. Jøhndal, 2008.
#
require 'jobs'

class Validator < Task
  def initialize
    super('validator')
  end

  protected

  def run!(logger)
    check_manual_morphology(logger)
    check_lemmata(logger)
    check_orphaned_tokens(logger)
    check_changesets_and_changes(logger)
  end

  private

  def check_changesets_and_changes(logger)
    failures = false

    # Check Audit first so that any fixes that lead to empty audits
    # can be handled by validation of Changeset
    changes = Audit.find(:all)
    changes.each do |change|
      change.errors.each_full { |msg| logger.error { "Audit #{change.id}: #{msg}" } } unless change.valid?

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
          logger.warn { "Audit #{change.id}: Removing empty diff" }
          change.destroy
        else
          logger.warn { "Audit #{change.id}: Removing empty diff and rearranging version numbers" }
          change.destroy
          others.each do |v|
            v.decrement!(:version)
          end
        end
      end
    end
  end

  def check_orphaned_tokens(logger)
    Token.find_each(:include => [ :sentence ], :conditions => [ "sentences.id is null" ]) do |t|
      logger.warn { "Token #{t.id} is orphaned" }
    end
  end

  def check_lemmata(logger)
    orphans = Lemma.find(:all, :include => [:tokens], :conditions => ["lemmata.foreign_ids IS NULL and tokens.id IS NULL"])
    orphans.each do |o| 
      logger.warn { "Lemma #{o.id} (#{o.export_form}) is orphaned. Destroying." }
      o.destroy
    end

    candidates = Lemma.find(:all, :conditions => [ "variant IS NOT NULL" ])
    candidates.each do |o|
      if c = o.language.lemmata.find(:first, :conditions => [ "lemma = ? and variant is null", o.lemma ])
        logger.warn { "Lemma base form #{o.lemma} occurs both with and without variant numbers" }
      end
    end
  end

  def check_manual_morphology(logger)
    closed = "^(#{MorphFeatures::OPEN_MAJOR.join('|')})"
    PartOfSpeech.find(:all, :conditions => ["tag not rlike ?", closed]).each do |pos|
      pos.lemmata.each do |lemma|
        language = lemma.language

        lemma.tokens.each do |token|
          unless language.inflections.exists?(:form => token.form, :morphology_id => token.morphology_id, :manual_rule => true)
            log_token_error(logger, token, "Closed class morph-features but no manual rule")
          end
        end
      end
    end
  end

  def log_token_error(logger, token, msg)
    logger.warn { "Token #{token.id} (sentence #{token.sentence.id}) '#{token.form}' (#{token.language.name}): #{msg}" }
  end
end
