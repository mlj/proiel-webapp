class AddBinderId < ActiveRecord::Migration
  def up
    add_column :tokens, :binder_id, :integer, null: true
  end

  def down
    remove_column :tokens, :binder_id
  end
end
