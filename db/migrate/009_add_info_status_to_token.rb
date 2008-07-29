class AddInfoStatusToToken < ActiveRecord::Migration
  def self.up
    add_column :tokens, :info_status, :enum, :null => true, :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old]
  end

  def self.down
    remove_column :tokens, :info_status
  end
end
