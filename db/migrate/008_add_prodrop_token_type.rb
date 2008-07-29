class AddProdropTokenType < ActiveRecord::Migration
  def self.up
    change_column :tokens, :sort, :enum, :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end, :word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation, :spacing_punctuation, :left_bracketing_punctuation, :right_bracketing_punctuation, :prodrop], :default     => :word, :null => false
  end

  def self.down
    change_column :tokens, :sort, :enum, :limit => [:text, :punctuation, :empty_dependency_token, :lacuna_start, :lacuna_end, :word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation, :spacing_punctuation, :left_bracketing_punctuation, :right_bracketing_punctuation], :default     => :word, :null => false
  end
end
