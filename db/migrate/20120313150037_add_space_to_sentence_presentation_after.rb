class AddSpaceToSentencePresentationAfter < ActiveRecord::Migration
  def up
    Sentence.without_auditing do
      SourceDivision.find_each do |sd|
        sd.sentences.order('sentence_number DESC').offset(1).each do |s|
          unless s.tokens.last.presentation_after and s.tokens.last.presentation_after[/\s$/]
            unless s.presentation_after and s.presentation_after[/\s$/]
              s.update_attribute :presentation_after, (s.presentation_after || '') + ' '
            end
          end
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
