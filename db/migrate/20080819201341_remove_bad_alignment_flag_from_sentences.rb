class RemoveBadAlignmentFlagFromSentences < ActiveRecord::Migration
  def self.up
    Sentence.find(:all, :conditions => { :bad_alignment_flag => true }).each do |s|
      originator = s.annotator || User.find_by_login("mlj")
      Note.create! :originator => originator, :notable => s, :contents => 'Bad sentence division'
    end

    remove_column :sentences, :bad_alignment_flag
  end

  def self.down
    add_column :sentences, :bad_alignment_flag, :boolean
  end
end
