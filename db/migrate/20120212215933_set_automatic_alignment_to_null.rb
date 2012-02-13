class SetAutomaticAlignmentToNull < ActiveRecord::Migration
  def self.up
    execute "UPDATE tokens SET automatic_token_alignment = NULL where automatic_token_alignment = 0;"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
