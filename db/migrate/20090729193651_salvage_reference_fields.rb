class SalvageReferenceFields < ActiveRecord::Migration
  def self.up
    Source.find_each { |s| s.reindex! }

    # Salvage verse numbers
    Sentence.find_each do |s|
      next unless s.tokens.morphology_annotatable.first # some sentences are broken; this is not the place to deal with this
      next unless s.tokens.morphology_annotatable.first.verse # some sentences are broken; this is not the place to deal with this
      s.tokens.morphology_annotatable.each do |t|
        t.reference_fields = s.reference_fields.merge({ "verse" => t.verse })
        t.save_without_validation!
      end
    end

    remove_column :tokens, :verse
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
