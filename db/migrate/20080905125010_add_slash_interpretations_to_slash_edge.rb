class AddSlashInterpretationsToSlashEdge < ActiveRecord::Migration
  def self.up
    create_table :slash_edge_interpretations do |t|
      t.string :tag, :limit => 64, :null => false
      t.string :summary, :limit => 128, :null => false
    end

    SlashEdgeInterpretation.disable_auditing
    SlashEdge.disable_auditing
    SlashEdgeInterpretation.create! :tag => "predicate-identity", :summary => "Predicate identity"
    SlashEdgeInterpretation.create! :tag => "subject", :summary => "Subject"
    SlashEdgeInterpretation.create! :tag => "shared-argument", :summary => "Shared argument"

    add_column :slash_edges, :slash_edge_interpretation_id, :integer, :null => false

    sentences = []
    SlashEdge.find(:all).each do |e|
      # Oops! we have some nil slashees and slashers!
      sentences << e.slashee.sentence unless e.slashee.nil?
      sentences << e.slasher.sentence unless e.slasher.nil?
    end
    sentences.uniq!

    sentences.each do |s|
      s.dependency_graph.nodes.each do |n|
        n.slashes.each do |e|
          slasher_id, slashee_id = n.identifier, e.identifier
          edges = SlashEdge.find_all_by_slasher_id_and_slashee_id(slasher_id, slashee_id)

          raise "Multiple slash edges for #{slasher_id} → #{slashee_id}" if edges.length > 1
          raise "No slash edge for #{slasher_id} → #{slashee_id}" if edges.length < 1
          edge = edges.first

          interpretation = SlashEdgeInterpretation.find_by_tag(n.interpret_slash(e))
          edge.slash_edge_interpretation = interpretation
          edge.save!
        end
      end
    end
  end

  def self.down
    remove_column :slash_edges, :slash_edge_interpretation_id
    drop_table :slash_edge_interpretations
  end
end
