class AddProdropTokenType < ActiveRecord::Migration
  def self.up
    change_column :tokens, :sort, :enum, :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end, :prodrop], :default => :text, :null => false
  end

  def self.down
    change_column :tokens, :sort, :enum, :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end], :default     => :text, :null => false
  end
end
