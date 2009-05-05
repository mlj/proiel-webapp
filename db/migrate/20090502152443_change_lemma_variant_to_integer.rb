class ChangeLemmaVariantToInteger < ActiveRecord::Migration
  def self.up
    change_column :lemmata, :variant, :integer, :limit => 2
  end

  def self.down
    change_column :lemmata, :variant, :string, :limit => 16
  end
end
