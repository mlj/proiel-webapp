class AddRelationsTable < ActiveRecord::Migration

  ALL_RELS = {
    :adnom=>{:priority=>:primary},
    :adv=>{:priority=>:primary},
    :ag=>{:priority=>:primary},
    :apos=>{:priority=>:primary},
    :arg=>{:priority=>:primary},
    :atr=>{:priority=>:primary},
    :aux=>{:priority=>:primary},
    :comp=>{:priority=>:primary},
    :narg=>{:priority=>:primary},
    :nonsub=>{:priority=>:primary},
    :obj=>{:priority =>:primary},
    :obl=>{:priority=>:primary},
    :parpred=>{:priority=>:primary},
    :part=>{:priority=>:primary},
    :per=>{:priority=>:primary},
    :piv=>{:priority=>:primary},
    :pred=>{:priority =>:primary},
    :xadv=>{:priority=>:primary},
    :xobj=>{:priority=>:primary},
    :rel=>{:priority=>:primary},
    :sub=>{:priority =>:primary},
    :voc=>{:priority=>:primary},
    :xsub=>{:priority=>:secondary},
    :pid=>{:priority=>:secondary}
  }


  EQUIVALENCES = {
    :obj => :arg,
    :obl => :arg,
    :obl => :per,
    :part => :adnom,
    :atr => :rel,
    :atr => :adnom,
    :apos => :rel,
    :apos => :adnom,
    :rel => :adnom,
    :adv => :per,
    :arg => :nonsub,
    :per => :nonsub,
    :narg => :adnom
  }

  def self.up
    rename_table :slash_edge_interpretations, :relations
    rename_column :slash_edges, :slash_edge_interpretation_id, :relation_id

    Relation.disable_auditing
    Token.disable_auditing

    add_column :relations, :primary_relation, :boolean, :null => false, :default => false
    add_column :relations, :secondary_relation, :boolean, :null => false, :default => false

    execute("UPDATE relations SET secondary_relation = true")

    ALL_RELS.each do |tag, data|
      s = Relation.find_by_tag(tag)
      raise "Data inconsistency" unless s
      s.primary_relation = true if data[:priority] == :primary
      s.save!
    end

    add_column :tokens, :relation_id, :integer, :null => true
    add_index "tokens", ["relation_id"]

    SlashEdge.find_all_by_relation_id(Relation.find_by_tag('piv').id).each do |se|
      se.relation = Relation.find_by_tag('xobj')
      se.save!
    end

    Relation.all.each do |r|
      Token.find(:all, :conditions => { :relation => r.tag }).each do |t|
        if r.tag == 'piv'
          t.relation = Relation.find_by_tag('xobj')
        else
          t.relation = r
        end
        t.save_without_validation!
      end
    end

    Relation.find_by_tag('piv').destroy

    i = Token.count(:conditions => [ 'relation is not null and relation_id is null' ])
    raise "Inconsistency" unless i.zero?

    create_table :relation_equivalences, :id => false do |t|
      t.integer :subrelation_id, :null => false
      t.integer :superrelation_id, :null => false
    end

    EQUIVALENCES.each do |subrelation, superrelation|
      returning RelationEquivalence.new do |re|
        re.subrelation_id = Relation.find_by_tag(subrelation).id
        re.superrelation_id = Relation.find_by_tag(superrelation).id
        re.save!
      end
    end

    remove_column :tokens, :relation
  end

  def self.down
    SlashEdgeInterpretation.disable_auditing
    Token.disable_auditing

    add_column :tokens, :relation, :string, :limit => 20

    SlashEdgeInterpretation.all.each do |r|
      Token.find(:all, :conditions => { :relation_id => r.id }).each do |t|
        t.relation = r.tag
        t.save_without_validation!
      end
    end

    remove_column :tokens, :relations_id
    rename_table :relations, :slash_edge_interpretations
    remove_table :relation_equivalences
    remove_column :slash_edge_interpretations, :secondary_relation
    remove_column :slash_edge_interpretations, :primary_relation
  end
end
