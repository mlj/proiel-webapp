class SentenceAlignment < ActiveRecord::Base
  belongs_to :primary_sentence, :class_name => 'Sentence', :foreign_key => 'primary_sentence_id'
  belongs_to :secondary_sentence, :class_name => 'Sentence', :foreign_key => 'primary_sentence_id'
end
