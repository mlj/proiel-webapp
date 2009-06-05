class AccDiscToAccSit < ActiveRecord::Migration
  def self.up
    change_column :tokens, :info_status, :enum, :null => true,
    :limit => [:new, :acc, :acc_gen, :acc_sit, :acc_disc, :acc_inf, :old, :old_inact, :no_info_status, :info_unannotatable]
    execute("UPDATE tokens SET info_status = 'acc_sit' WHERE info_status = 'acc_disc'")
    change_column :tokens, :info_status, :enum, :null => true,
    :limit => [:new, :acc, :acc_gen, :acc_sit, :acc_inf, :old, :old_inact, :no_info_status, :info_unannotatable]
  end

  def self.down
    change_column :tokens, :info_status, :enum, :null => true,
    :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_sit, :acc_inf, :old, :old_inact, :no_info_status, :info_unannotatable]
    execute("UPDATE tokens SET info_status = 'acc_disc' WHERE info_status = 'acc_sit'")
    change_column :tokens, :info_status, :enum, :null => true,
    :limit => [:new, :acc, :acc_gen, :acc_disc, :acc_inf, :old, :old_inact, :no_info_status, :info_unannotatable]
  end
end
