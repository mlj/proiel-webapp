class Deforestation < ActiveRecord::Migration
  require 'db/migrate/deforestation'

  def self.up
    Token.disable_auditing
    Sentence.disable_auditing

    # Remove any sentence alignment information, since this will have
    # to be regenerated
    execute("UPDATE sentences SET unalignable = false")
    execute("UPDATE sentences SET automatic_alignment = false")
    execute("UPDATE sentences SET sentence_alignment_id = null")

    # Renumber sentences so that there is a new numbering within each
    # SourceDivision instead of reflecting the old division into books
    SourceDivision.find_each do |sd|
      change = sd.sentences.first.sentence_number - 1 
      execute("UPDATE sentences SET sentence_number = sentence_number - #{change} WHERE source_division_id = #{sd.id}")
    end

    pred_relation_id = Relation.find_by_tag('pred').id

    sids = Token.find_by_sql("select * from tokens t1 left join tokens t2 on t1.sentence_id = t2.sentence_id where t1.relation_id = #{pred_relation_id} and t1.head_id is null and t2.relation_id = #{pred_relation_id} and t2.head_id is null and t1.id != t2.id group by t1.sentence_id").map(&:sentence_id)
    n = sids.size
    
    sids.each_with_index do |sid, i|
      s = Sentence.find(sid)
      roots = s.dependency_tokens.select { |dt| dt.head_id == nil and dt.relation.tag == "pred" }
      raise "Cannot partition a sentence in only one part" unless roots.size > 1
      STDERR.puts "Partitioning sentence #{i + 1} of #{n}"
      s.partition!(roots)
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
