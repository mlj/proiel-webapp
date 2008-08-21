class RemoveMorphtagPerformanceFromToken < ActiveRecord::Migration
  def self.up
    remove_column :tokens, :morphtag_performance
  end

  def self.down
    add_column :tokens, :morphtag_performance, :enum, :limit => [:failed, :overridden, :suggested, :picked]
  end
end
