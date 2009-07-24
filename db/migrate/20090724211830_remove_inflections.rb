require 'db/migrate/remove_inflections'

class RemoveInflections < ActiveRecord::Migration
  def self.up
    remove_inflections
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
