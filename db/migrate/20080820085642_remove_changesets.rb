class RemoveChangesets < ActiveRecord::Migration
  def self.up
    add_column :audits, :user_id, :integer, :null => false
    add_column :audits, :created_at, :datetime, :null => false

    execute("UPDATE audits LEFT JOIN changesets ON changeset_id = changesets.id SET audits.user_id = changesets.user_id")
    execute("UPDATE audits LEFT JOIN changesets ON changeset_id = changesets.id SET audits.created_at = changesets.created_at")

    drop_table :changesets
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
