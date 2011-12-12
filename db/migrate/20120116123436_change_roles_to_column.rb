class ChangeRolesToColumn < ActiveRecord::Migration
  def up
    add_column :users, :role, :string, :length => 16, :null => false, :default => ''

    execute("UPDATE users LEFT JOIN roles ON users.role_id = roles.id SET users.role = roles.code")

    remove_column :users, :role_id

    drop_table :roles
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
