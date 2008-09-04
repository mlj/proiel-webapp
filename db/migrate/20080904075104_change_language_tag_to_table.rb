class ChangeLanguageTagToTable < ActiveRecord::Migration
  def self.up
    create_table :languages do |t|
      t.string :iso_code, :limit => 3, :null => false
      t.string :name, :limit => 32, :null => false
    end
    
    add_index :languages, ["iso_code"], :unique => true
    
    rename_column :lemmata, :language, :old_language # to avoid clashes with new association
    add_column :lemmata, :language_id, :integer, :null => false

    Lemma.reset_column_information
    Language.reset_column_information

    Language.create!(:iso_code => 'la', :name => 'Latin') # properly: la
    Language.create!(:iso_code => 'cu', :name => 'Old Church Slavonic') # properly: chu
    Language.create!(:iso_code => 'hy', :name => 'Classical Armenian') # properly: xcl
    Language.create!(:iso_code => 'grc', :name => 'Ancient Greek (to 1453)')
    Language.create!(:iso_code => 'got', :name => 'Gothic')

    Lemma.find(:all).group_by(&:old_language).each do |language, rows|
      raise "Lemmata without language!" if language.blank?
      p = Language.find_by_iso_code(language)

      rows.each do |row|
        row.language = p
        row.save!
      end
    end

    remove_index :lemmata, :name => "index_lemmata_on_lang"
    remove_column :lemmata, :old_language
    add_index :lemmata, :language_id

    # Update sources
    rename_column :sources, :language, :old_language # to avoid clashes with new association
    add_column :sources, :language_id, :integer, :null => false
    Source.reset_column_information
 
    Source.find(:all).group_by(&:old_language).each do |language, rows|
      p = Language.find_by_iso_code(language)

      rows.each do |row|
        row.language = p
        row.save!
      end
    end

    remove_column :sources, :old_language
  end

  def self.down
    add_column :sources, :string, :language, :limit => 3, :default => "", :null => false
    remove_column :sources, :language_id
    remove_index :lemmata, :language_id
    remove_index :lemmata, :name => "lemmata_uniqueness"
    add_column :lemmata, "language", :string, :limit => 3
    add_index :lemmata, ["language"], :name => "index_lemmata_on_lang"
    add_index "lemmata", ["lemma", "part_of_speech_id", "variant", "language"], :name => "lemmata_uniqueness", :unique => true
    remove_column :lemmata, :language_id
    remove_index :languages, :iso_code
    drop_table :languages
  end
end
