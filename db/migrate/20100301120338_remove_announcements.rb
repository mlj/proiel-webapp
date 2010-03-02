class RemoveAnnouncements < ActiveRecord::Migration
  def self.up
    drop_table :announcements
  end

  def self.down
    create_table "announcements", :force => true do |t|
      t.text     "message"
      t.datetime "starts_at"
      t.datetime "ends_at"
      t.integer  "role_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
