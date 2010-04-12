class RemoveEnums < ActiveRecord::Migration
  def self.up
    update("alter table tokens modify info_status varchar(20);")
  end

  def self.down
    remove_column :tokens, :info_status
    add_column :tokens, :info_status, :enum, :limit => [:new, :acc, :acc_gen, :acc_sit, :acc_inf, :old, :old_inact, :no_info_status, :info_unannotatable]
  end
end
