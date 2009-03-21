class ChangedSlashEdgeInterpretations < ActiveRecord::Migration
  def self.up
    SlashEdgeInterpretation.disable_auditing
    SlashEdge.disable_auditing

    # Remove loose slashes
    execute("delete slash_edges from slash_edges left join tokens as slasher on slasher_id = slasher.id left join tokens as slashee on slashee_id = slashee.id where slashee.relation is null or slasher.relation is null;")

    # Insert the new relations (= all the primary relations) into the database
    PROIEL::PRIMARY_RELATIONS.each do |identifier, tag|
      SlashEdgeInterpretation.create! :tag => tag.code.to_s, :summary => tag.summary
    end

    # Change the subject tag to xsub
    subject_sei = SlashEdgeInterpretation.find_by_tag("subject")
    subject_sei.tag = "xsub"
    subject_sei.summary = "external subject"
    subject_sei.save!

    # Change the predicate-identity tag to pid
    predicate_identity_sei = SlashEdgeInterpretation.find_by_tag("predicate-identity")
    predicate_identity_sei.tag = "pid"
    predicate_identity_sei.save!

    # Change the shared argument interpretation to the relation of the slashee
    SlashEdge.find_all_by_slash_edge_interpretation_id(SlashEdgeInterpretation.find_by_tag("shared-argument").id).each do |se|
      new_relation = Token.find(se.slashee_id).relation
      se.slash_edge_interpretation_id = SlashEdgeInterpretation.find_by_tag(new_relation).id
      se.save!
    end  

    # Now destroy the shared-argument tag in SlashEdgeInterpretations
    sa = SlashEdgeInterpretation.find_by_tag("shared-argument")
    sa.destroy
  end

  def self.down
    # Change the xsub tag to subject
    subject_sei = SlashEdgeInterpretation.find_by_tag("xsub")
    subject_sei.tag = "subject"
    subject_sei.summary = "Subject"
    subject_sei.save!

    # Change the pid tag to predicate-identity
    predicate_identity_sei = SlashEdgeInterpretation.find_by_tag("pid")
    predicate_identity_sei.tag = "predicate-identity"
    predicate_identity_sei.save!

    # Create a shared-argument tag
    SlashEdgeInterpretation.create! :tag => "shared-argument", :summary => "Shared argument"

    # Set the shared-argument tag on everything which is not predicate-identity or xsub
    SlashEdge.find(:all).each do |se|
      unless (se.slash_edge_interpretation_id == subject_sei.id or se.slash_edge_interpretation_id == predicate_identity_sei.id)
        se.slash_edge_interpretation_id = SlashEdgeInterpretation.find_by_tag("shared-argument").id
        se.save!
      end
    end

    # Delete the tags used instead of shared-argument
    SlashEdgeInterpretation.find(:all).each do |sei|
      unless (sei.tag == "subject" or sei.tag == "predicate-identity" or sei.tag == "shared-argument")
        sei.destroy
      end
    end
  end
end
