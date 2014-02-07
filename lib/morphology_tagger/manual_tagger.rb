#!/usr/bin/env ruby
#
# manual_tagger.rb - Overwrites all morphology that does not match manual rules
#
# Written by Marius L. Jøhndal, 2008.
#
class ManualTagger
  def initialize(*source_ids)
    super('manual-tagger')
    @source_ids = source_ids.flatten
  end

  protected

  def run!(logger)
    Source.find(@source_ids).each do |source|
      source.sentences.annotated.each do |sentence|
        sentence.tokens.takes_morphology.each do |token|
          mf = token.morph_features

          if mf and mf.is_closed?
            next unless mf.valid?

            result, pick, *manual_tags = token.language.guess_morphology(token.form, nil, :force_method => :manual_rules)
            manual_tags.collect!(&:first) # ditch the weights

            if manual_tags.length == 0
              log_token_error(logger, token, "Tagged with closed class morphology but not found in definition.")
            else
              unless manual_tags.any? { |m| token.morph_features.compatible?(m) }
                if manual_tags.length == 1
                  from, to = ml, manual_tags.first
                  if sentence.is_reviewed?
                    logger.info { "Changing token #{token.id} (reviewed): #{from} -> #{to}" }
                  else
                    logger.info { "Changing token #{token.id}: #{from} -> #{to}" }
                  end
                  token.morph_features = to
                else
                  log_token_error(logger, token, "Closed class morphology does not match: #{token.morph_features} (actual) != #{manual_tags.map(&:to_s).join(' | ')} (expected)")
                end
              end
            end
          end
        end
      end
    end
  end

  def log_token_error(logger, token, msg)
    logger.error { "Token #{token.id} (sentence #{token.sentence.id}) '#{token.form}': #{msg}" }
  end
end

v = ManualTagger.new
v.execute!
