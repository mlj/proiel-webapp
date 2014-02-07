class AddWeightToInflections < ActiveRecord::Migration
  def change
    add_column :inflections, :weight, :integer, null: false, default: 0, length: 3
  end
end
