class RemoveEditorialColumnsFromLemmata < ActiveRecord::Migration
  def down
    %w(conjecture unclear reconstructed nonexistant inflected).each do |column|
      add_column :lemmata, column.to_sym, :boolean
    end
  end

  def up
    %w(conjecture unclear reconstructed nonexistant inflected).each do |column|
      remove_column :lemmata, column.to_sym
    end
  end
end
