class RenameInfoStatusToInformationStatusTag < ActiveRecord::Migration
  def change
    rename_column :tokens, :info_status, :information_status_tag
  end
end
