class ChangeLanguageToAggregation < ActiveRecord::Migration
  LANGUAGE_MAP = {1=>'lat', 2=>'chu', 3=>'xcl', 4=>'grc', 5=>'got', 6=>'non'}
  LANGUAGE_TABLES = %w{inflections lemmata sources}

  def self.up
    LANGUAGE_TABLES.each do |tab|
      change_column tab, :language_id, :string, :limit => 3, :null => false, :default => ""
      rename_column tab, :language_id, :language
      LANGUAGE_MAP.each do |old_key, new_key|
        execute("UPDATE #{tab} SET language = '#{new_key}' WHERE language = #{old_key}")
      end
    end

    drop_table :languages
  end

  def self.down
    create_table "languages", :force => true do |t|
      t.string "iso_code", :limit => 3,  :default => "", :null => false
      t.string "name",     :limit => 32, :default => "", :null => false
    end

    add_index "languages", ["iso_code"], :name => "index_languages_on_iso_code", :unique => true

    LANGUAGE_TABLES.each do |tab|
      LANGUAGE_MAP.each do |old_key, new_key|
        execute("UPDATE #{tab} SET language = '#{old_key}' WHERE language = #{new_key}")
      end
      change_column tab, :language, :integer, :null => false, :default => 0
      rename_column tab, :language, :language_id
    end
  end
end
