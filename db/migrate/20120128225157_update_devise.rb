class UpdateDevise < ActiveRecord::Migration
  def change
    remove_column :users, :remember_token
    add_column :users, :reset_password_sent_at, :datetime
  end
end
