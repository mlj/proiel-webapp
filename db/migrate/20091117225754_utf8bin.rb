class Utf8bin < ActiveRecord::Migration
  def self.up
    tables.each { |table| execute("alter table #{table} character set utf8 collate utf8_bin") }
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
