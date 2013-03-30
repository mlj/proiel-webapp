class DropTableRelationEquivalences < ActiveRecord::Migration
  def up
    rename_column :tokens, :relation_id, :relation_tag
    rename_column :slash_edges, :relation_id, :relation_tag

    change_column :tokens, :relation_tag, :string, :limit => 8
    change_column :slash_edges, :relation_tag, :string, :limit => 8, :null => false

    [:tokens, :slash_edges].each do |t|
      execute("UPDATE #{t} SET relation_tag = 'pid' WHERE relation_tag = 1")
      execute("UPDATE #{t} SET relation_tag = 'xsub' WHERE relation_tag = 2")
      execute("UPDATE #{t} SET relation_tag = 'aux' WHERE relation_tag = 4")
      execute("UPDATE #{t} SET relation_tag = 'xadv' WHERE relation_tag = 5")
      execute("UPDATE #{t} SET relation_tag = 'atr' WHERE relation_tag = 6")
      execute("UPDATE #{t} SET relation_tag = 'comp' WHERE relation_tag = 7")
      execute("UPDATE #{t} SET relation_tag = 'narg' WHERE relation_tag = 8")
      execute("UPDATE #{t} SET relation_tag = 'rel' WHERE relation_tag = 9")
      execute("UPDATE #{t} SET relation_tag = 'parpred' WHERE relation_tag = 10")
      execute("UPDATE #{t} SET relation_tag = 'voc' WHERE relation_tag = 11")
      execute("UPDATE #{t} SET relation_tag = 'arg' WHERE relation_tag = 12")
      execute("UPDATE #{t} SET relation_tag = 'pred' WHERE relation_tag = 13")
      execute("UPDATE #{t} SET relation_tag = 'nonsub' WHERE relation_tag = 14")
      execute("UPDATE #{t} SET relation_tag = 'ag' WHERE relation_tag = 15")
      execute("UPDATE #{t} SET relation_tag = 'part' WHERE relation_tag = 16")
      execute("UPDATE #{t} SET relation_tag = 'obj' WHERE relation_tag = 17")
      execute("UPDATE #{t} SET relation_tag = 'adv' WHERE relation_tag = 18")
      execute("UPDATE #{t} SET relation_tag = 'per' WHERE relation_tag = 19")
      execute("UPDATE #{t} SET relation_tag = 'apos' WHERE relation_tag = 20")
      execute("UPDATE #{t} SET relation_tag = 'adnom' WHERE relation_tag = 21")
      execute("UPDATE #{t} SET relation_tag = 'sub' WHERE relation_tag = 22")
      execute("UPDATE #{t} SET relation_tag = 'obl' WHERE relation_tag = 24")
      execute("UPDATE #{t} SET relation_tag = 'xobj' WHERE relation_tag = 25")
      execute("UPDATE #{t} SET relation_tag = 'expl' WHERE relation_tag = 26")
    end

    drop_table :relations
    drop_table :relation_equivalences
  end

  def down
    create_table "relation_equivalences", :id => false, :force => true do |t|
      t.integer "subrelation_id",   :null => false
      t.integer "superrelation_id", :null => false
    end

    create_table "relations", :force => true do |t|
      t.string  "tag",                :limit => 64,  :default => "",    :null => false
      t.string  "summary",            :limit => 128, :default => "",    :null => false
      t.boolean "primary_relation",                  :default => false, :null => false
      t.boolean "secondary_relation",                :default => false, :null => false
    end

    [:tokens, :slash_edges].each do |t|
      execute("UPDATE #{t} SET relation_tag = 1 WHERE relation_tag = 'pid'")
      execute("UPDATE #{t} SET relation_tag = 2 WHERE relation_tag = 'xsub'")
      execute("UPDATE #{t} SET relation_tag = 4 WHERE relation_tag = 'aux'")
      execute("UPDATE #{t} SET relation_tag = 5 WHERE relation_tag = 'xadv'")
      execute("UPDATE #{t} SET relation_tag = 6 WHERE relation_tag = 'atr'")
      execute("UPDATE #{t} SET relation_tag = 7 WHERE relation_tag = 'comp'")
      execute("UPDATE #{t} SET relation_tag = 8 WHERE relation_tag = 'narg'")
      execute("UPDATE #{t} SET relation_tag = 9 WHERE relation_tag = 'rel'")
      execute("UPDATE #{t} SET relation_tag = 10 WHERE relation_tag = 'parpred'")
      execute("UPDATE #{t} SET relation_tag = 11 WHERE relation_tag = 'voc'")
      execute("UPDATE #{t} SET relation_tag = 12 WHERE relation_tag = 'arg'")
      execute("UPDATE #{t} SET relation_tag = 13 WHERE relation_tag = 'pred'")
      execute("UPDATE #{t} SET relation_tag = 14 WHERE relation_tag = 'nonsub'")
      execute("UPDATE #{t} SET relation_tag = 15 WHERE relation_tag = 'ag'")
      execute("UPDATE #{t} SET relation_tag = 16 WHERE relation_tag = 'part'")
      execute("UPDATE #{t} SET relation_tag = 17 WHERE relation_tag = 'obj'")
      execute("UPDATE #{t} SET relation_tag = 18 WHERE relation_tag = 'adv'")
      execute("UPDATE #{t} SET relation_tag = 19 WHERE relation_tag = 'per'")
      execute("UPDATE #{t} SET relation_tag = 20 WHERE relation_tag = 'apos'")
      execute("UPDATE #{t} SET relation_tag = 21 WHERE relation_tag = 'adnom'")
      execute("UPDATE #{t} SET relation_tag = 22 WHERE relation_tag = 'sub'")
      execute("UPDATE #{t} SET relation_tag = 24 WHERE relation_tag = 'obl'")
      execute("UPDATE #{t} SET relation_tag = 25 WHERE relation_tag = 'xobj'")
      execute("UPDATE #{t} SET relation_tag = 26 WHERE relation_tag = 'expl'")
    end

    change_column :tokens, :relation_tag, :integer
    change_column :slash_edges, :relation_tag, :integer, :null => false

    rename_column :tokens, :relation_tag, :relation_id
    rename_column :slash_edges, :relation_tag, :relation_id
  end
end
