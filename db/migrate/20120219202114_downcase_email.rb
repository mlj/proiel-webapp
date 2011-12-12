class DowncaseEmail < ActiveRecord::Migration
  def up
    User.find_each do |u|
      u.update_attributes! :email => u.email.downcase
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
