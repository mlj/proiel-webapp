class AddRequestUuidToAudits < ActiveRecord::Migration[5.1]
  def change
    add_column :audits, :request_uuid, :string
    add_index :audits, :request_uuid
  end
end
