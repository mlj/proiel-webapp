class FixReferences < ActiveRecord::Migration
  CODES = %w{gnt-greeknt perseus-vulgate-synth usc-marianus-synth wulfila-gothicnt}

  def self.up
    sources = CODES.map { |code| Source.find_by_code(code) }

    sources.map(&:source_divisions).flatten.each do |sd|
      chapter_number = sd.title.split(/\s/).last

      # Deal with SDs
      p = Hpricot.XML(sd.presentation)
      m = p.at("//milestone[@unit='chapter']")
      raise "Lacking milestone in source division #{sd.title}" unless m
      if m["n"] != chapter_number
        m.raw_attributes.update({"n" => chapter_number})
        sd.presentation = p.to_s
        sd.save!
      end

      # Deal with the first sentence
      s = sd.sentences.first
      p = Hpricot.XML(s.presentation)
      m = p.at("//milestone[@unit='chapter']")
      raise "Lacking milestone in sentence #{s.id}" unless m
      if m["n"] != chapter_number
        m.raw_attributes.update({"n" => chapter_number})
        s.presentation = p.to_s
        begin
          s.save!
        rescue
          STDERR.puts "Saving sentence #{s.id} without validation"
          s.save_without_validation
        end
      end
    end

    # Rebuild reference fidlds
    sources.each { |source| source.reindex! }
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
