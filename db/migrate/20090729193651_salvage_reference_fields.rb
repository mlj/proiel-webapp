class SalvageReferenceFields < ActiveRecord::Migration
  def self.up
    Source.find_each { |s| s.reindex! }

    # Salvage verse numbers
    execute("update tokens set reference_fields = concat('verse=', verse) where empty_token_sort is null;")

    remove_column :tokens, :verse
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
