#!/usr/bin/env ruby
#
# validation.rb - Extra (i.e. non-model) data validation
#
# Written by Marius L. Jøhndal, 2008, 2011.
#
require 'jobs'

class Validator < Task
  def initialize
    super('validator')
  end

  protected

  def run!(logger)
#    check_manual_morphology(logger)
    check_lemmata(logger)
    check_orphaned_tokens(logger)
#    check_changesets_and_changes(logger)
  end

  private

  def check_changesets_and_changes(logger)
    failures = false

    # Check Audit first so that any fixes that lead to empty audits
    # can be handled by validation of Changeset
    changes = Audit.find(:all)
    changes.each do |change|
      change.errors.to_a.each { |msg| logger.error { "Audit #{change.id}: #{msg}" } } unless change.valid?

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
    Token.includes(:sentence).where("sentences.id is null").each do |t|
      logger.warn { "Token #{t.id} (#{t.to_s}) is orphaned" }
    end
  end

  def check_lemmata(logger)
    Lemma.includes(:tokens).where('lemmata.foreign_ids IS NULL and tokens.id IS NULL').each do |o|
      logger.warn { "Lemma #{o.id} (#{o.to_s}) is orphaned. Destroying." }
      o.destroy
    end

    Lemma.joins("left join lemmata as b on lemmata.lemma = b.lemma and lemmata.part_of_speech_tag = b.part_of_speech_tag and lemmata.language_tag = b.language_tag").where(:variant => nil).where("b.variant IS NOT NULL").each do |l|
      puts "Lemma #{l.lemma} of language #{l.language_tag} occurs both with and without variant numbers"
    end
  end

  def check_manual_morphology(logger)
    closed_regexp = /^(#{MorphFeatures::OPEN_MAJOR.join('|')})/
    PartOfSpeechTag.all.select { |pos| pos.tag[closed_regexp] }.each do |pos|
      Lemma.find_by_part_of_speech(pos.tag).each do |lemma|
        lemma.tokens.each do |token|
          unless Inflection.exists?(:language => lemma.language, :form => token.form, :morphology => token.morphology, :manual_rule => true)
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
