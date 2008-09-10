class ExtendInfoStatusEnum < ActiveRecord::Migration
  def self.up
    change_column :tokens, :info_status, :enum, :null => true,
          :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old, :no_info_status, :info_unannotatable]
  end

  def self.down
    change_column :tokens, :info_status, :enum, :null => true,
          :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old]
  end
end
