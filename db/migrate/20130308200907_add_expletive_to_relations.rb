class AddExpletiveToRelations < ActiveRecord::Migration
  def up
    execute("INSERT INTO relations VALUES (26, 'expl', 'Expletive', 1, 1)")
  end

  def down
    execute("DELETE FROM relations WHERE id = 26")
  end
end
