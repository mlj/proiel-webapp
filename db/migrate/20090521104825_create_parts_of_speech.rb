class CreatePartsOfSpeech < ActiveRecord::Migration
  POS_SUMMARIES = {
    "Nb" => "common noun",
    "Ne" => "proper noun",
    "Pp" => "personal pronoun",
    "Pr" => "relative pronoun",
    "Pd" => "demonstrative pronoun",
    "Ps" => "possessive pronoun",
    "Pk" => "personal reflexive pronoun",
    "Pt" => "possessive reflexive pronoun",
    "Pc" => "reciprocal pronoun",
    "Pi" => "interrogative pronoun",
    "Px" => "indefinite pronoun",
    "Ma" => "cardinal numeral",
    "Mo" => "ordinal numeral",
    "V-" => "verb",
    "A-" => "adjective",
    "S-" => "article",
    "Df" => "adverb",
    "Dq" => "relative adverb",
    "Du" => "interrogative adverb",
    "R-" => "preposition",
    "C-" => "conjunction",
    "G-" => "subjunction",
    "F-" => "foreign word",
    "I-" => "interjection",
  }

  POS_ABBREVIATED_SUMMARIES = POS_SUMMARIES.merge({
    "Pp" => "pers. pron.",
    "Pr" => "rel. pron.",
    "Pd" => "dem. pron.",
    "Ps" => "poss. pron.",
    "Pk" => "pers. refl. pron.",
    "Pt" => "poss. refl. pron.",
    "Pc" => "recipr. pron.",
    "Pi" => "interrog. pron.",
    "Px" => "indef. pron.",
    "Ma" => "card. num.",
    "Mo" => "ord. num.",
    "A-" => "adj.",
    "S-" => "art.",
    "Df" => "adv.",
    "Dq" => "rel. adv.",
    "Du" => "interrog. adv.",
    "R-" => "prep.",
    "C-" => "conj.",
    "G-" => "subj.",
    "I-" => "interj.",
  })

  def self.up
    create_table :parts_of_speech do |t|
      t.string "tag", :limit => 2, :null => false
      t.string "summary", :limit => 64, :null => false
      t.string "abbreviated_summary", :limit => 128, :null => false
    end
    
    add_index :parts_of_speech, ["tag"], :unique => true
    
    add_column :lemmata, :part_of_speech_id, :integer, :null => false

    Lemma.reset_column_information
    PartOfSpeech.reset_column_information

    Lemma.disable_auditing

    Lemma.find(:all).group_by(&:pos).each do |pos, rows|
      p = if pos.blank?
        announce("Lemma without POS! Substituting XX")
        PartOfSpeech.create! :tag => 'XX', :summary => 'Broken', :abbreviated_summary => 'Broken'
      else
        raise "Invalid POS #{pos}" unless POS_SUMMARIES.has_key?(pos) or POS_ABBREVIATED_SUMMARIES.has_key?(pos)
        PartOfSpeech.create! :tag => pos, :summary => POS_SUMMARIES[pos], :abbreviated_summary => POS_ABBREVIATED_SUMMARIES[pos]
      end

      rows.each do |row|
        row.part_of_speech = p
        row.save!
      end
    end

    remove_column :lemmata, :pos

    add_index "lemmata", ["lemma", "part_of_speech_id", "variant", "language_id"], :name => "lemmata_uniqueness", :unique => true
  end

  def self.down
    remove_index :lemmata, "lemmata_uniqueness"
    add_column :lemmata, :pos, :string, :limit => 2, :default => "", :null => false
    remove_column :lemmata, :part_of_speech_id
    remove_index :parts_of_speech, "tag"
    drop_table :parts_of_speech
  end
end
