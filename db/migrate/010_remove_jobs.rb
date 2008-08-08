class RemoveJobs < ActiveRecord::Migration
  def self.up
    execute("UPDATE changesets SET changer_id = 2 WHERE changer_type = 'Job'") # only one user ran these...
    remove_column :changesets, :changer_type
    rename_column :changesets, :changer_id, :user_id
    drop_table :jobs
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
