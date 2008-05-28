#!/usr/bin/env ruby
#
# manual_tagger.rb - Overwrites all morphology that does not match manual rules
#
# Written by Marius L. Jøhndal, 2008.
#
require 'jobs'

class ManualTagger < Task
  def initialize(*source_ids)
    super('manual-tagger')
    @source_ids = source_ids.flatten
  end

  protected

  def run!(logger)
    Source.find(@source_ids).each do |source|
      logger.info { "Working on source #{source.code}..." }
      source.annotated_sentences.each do |sentence|
        sentence.morphtaggable_tokens.each do |token|
          if (token.morphtag and not token.lemma_id) or (not token.morphtag and token.lemma_id)
            next
          end

          ml = token.morph_lemma_tag

          if ml and ml.morphtag.is_closed?
            next unless ml.morphtag.complete?  # FIXME: at some point eliminate

            manual_tags = TAGGER.get_manual_rule_matches(token.language, token.form)

            if manual_tags.length == 0
              log_token_error(logger, token, "Tagged with closed class morphology but not found in definition.")
            else
              unless manual_tags.any? { |m| token.morph_lemma_tag.morphtag.is_compatible?(m.morphtag) }
                if manual_tags.length == 1
                  from, to = ml, manual_tags.first
                  if sentence.is_reviewed?
                    logger.info { "Changing token #{token.id} (reviewed): #{from} -> #{to}" }
                  else
                    logger.info { "Changing token #{token.id}: #{from} -> #{to}" }
                  end
                  token.set_morph_lemma_tag!(to)
                else
                  log_token_error(logger, token, "Closed class morphology does not match: #{token.morphtag} (actual) != #{manual_tags.collect { |m| m.morphtag.to_s }.join(' | ')} (expected)")
                end
              end
            end
          end
        end
      end
    end
  end

  def log_token_error(logger, token, msg)
    logger.error { "Token #{token.id} (sentence #{token.sentence.id}) '#{token.form}' (#{token.language}): #{msg}" }
  end
end

v = ManualTagger.new
v.execute!('mlj')
