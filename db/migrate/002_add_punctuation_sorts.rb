class AddPunctuationSorts < ActiveRecord::Migration
  def self.up
    change_column :tokens, :sort, :enum, :limit => [:word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation, :spacing_punctuation, :left_bracketing_punctuation, :right_bracketing_punctuation], :default => :word, :null => false
  end

  def self.down
    change_column :tokens, :sort, :enum, :limit => [:word, :empty, :fused_morpheme, :enclitic, :nonspacing_punctuation], :default => :word, :null => false
  end
end
