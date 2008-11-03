class AddContrastGroupToToken < ActiveRecord::Migration
  def self.up
    add_column(:tokens, 'contrast_group', :string)
    add_index(:tokens, 'contrast_group')
  end

  def self.down
    remove_column(:tokens, 'contrast_group')
  end
end
