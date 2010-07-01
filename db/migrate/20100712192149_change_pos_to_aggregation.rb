class ChangePosToAggregation < ActiveRecord::Migration
  POS_MAP = {16=>"Dq", 5=>"S-", 22=>"Du", 11=>"Pr", 17=>"Ma", 6=>"V-", 23=>"F-", 12=>"Pd", 1=>"Nb", 18=>"Pc", 7=>"A-", 24=>"Pt", 13=>"Px", 2=>"Ne", 19=>"I-", 8=>"Pp", 14=>"Ps", 3=>"R-", 9=>"Df", 20=>"Pk", 15=>"Pi", 4=>"C-", 21=>"Mo", 10=>"G-"}
  POS_TABLES = %w{lemmata}

  def self.up
    POS_TABLES.each do |tab|
      change_column tab, :part_of_speech_id, :string, :limit => 2, :null => false, :default => ""
      rename_column tab, :part_of_speech_id, :part_of_speech
      POS_MAP.each do |old_key, new_key|
        execute("UPDATE #{tab} SET part_of_speech = '#{new_key}' WHERE part_of_speech = #{old_key}")
      end
    end

    drop_table :parts_of_speech
  end

  def self.down
    create_table "parts_of_speech", :force => true do |t|
      t.string "tag",                 :limit => 2,   :null => false
      t.string "summary",             :limit => 64,  :null => false
      t.string "abbreviated_summary", :limit => 128, :null => false
    end

    add_index "parts_of_speech", ["tag"], :name => "index_parts_of_speech_on_tag", :unique => true

    POS_TABLES.each do |tab|
      POS.each do |old_key, new_key|
        execute("UPDATE #{tab} SET part_of_speech = '#{old_key}' WHERE part_of_speech = #{new_key}")
      end
      change_column tab, :part_of_speech, :integer, :null => false, :default => 0
      rename_column tab, :part_of_speech, :part_of_speech_id
    end
  end
end
