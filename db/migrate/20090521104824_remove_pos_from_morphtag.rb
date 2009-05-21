class RemovePosFromMorphtag < ActiveRecord::Migration
  def self.up
    # Test lemma/token integrity
    Lemma.find_each do |l|
      next if l.tokens.empty?
      poses = l.tokens.map(&:morphtag).compact.map { |s| s[0, 2] }.uniq
      if poses.length != 1 or poses.first != l.pos
        #raise "Lemma.pos and token.morphtag.pos mismatch for lemma #{l.id}"
        puts "Lemma.pos and token.morphtag.pos mismatch for lemma #{l.id}. Information will be lost!"
      end
    end
    execute("UPDATE tokens SET morphtag = substr(morphtag, 3, 12)");
    rename_column :tokens, :morphtag, :morphology

    rename_column :inflections, :morphtag, :morphology
    execute("UPDATE inflections SET lemma = concat(lemma, ',', substr(morphology, 1, 2))")
    execute("UPDATE inflections SET morphology = substr(morphology, 3, 12)")

    rename_column :tokens, :source_morphtag, :source_morphology
    execute("UPDATE tokens SET source_lemma = '' WHERE source_morphology IS NOT NULL and source_lemma IS NULL")
    execute("UPDATE tokens SET source_lemma = concat(source_lemma, ',', substr(source_morphology, 1, 2))")
    execute("UPDATE tokens SET source_morphology = substr(source_morphology, 3, 12)")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
