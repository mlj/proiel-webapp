class RemoveManualRuleFromInflections < ActiveRecord::Migration
  def up
    remove_column :inflections, :manual_rule
  end

  def down
    add_column :inflections, :manual_rule, :boolean, null: false, default: false
  end
end
