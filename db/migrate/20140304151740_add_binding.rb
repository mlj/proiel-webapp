class AddBinderId < ActiveRecord::Migration
  def up
    add_column :tokens, :binder_id, :integer, null: true
    add_column :tokens, :old, :text
  end

  def down
    remove_column :tokens, :binder_id
    remove_column :tokens, :old
  end
end
