class NukeReferenceFields < ActiveRecord::Migration
  RANGE_PATTERN = /^(\d+)-(\d+)$/
  ARRAY_PATTERN = /^\[(.*)\]$/

  def self.compute(o, prev = {})
    o.read_attribute(:reference_fields).split(',').inject(prev) do |s, f|
      k, v = f.split('=')
      case v
      when RANGE_PATTERN
        v = (self.unserialize_reference_value($1))..(self.unserialize_reference_value($2))
      when ARRAY_PATTERN
        v = $1.split('-').map { |x| self.unserialize_reference_value(x) }
      else
        v = self.unserialize_reference_value(v)
      end
      s[k] = v
      s
    end
  end

  def self.unserialize_reference_value(v)
    if v.to_i.to_s == v
      v.to_i
    else
      v
    end
  end

  def self.compute_citations
    Source.all.each do |source|
      reference_format = YAML.load(source.reference_format)["token"]
      if reference_format
        reference_format.sub!('#title#, ', '')
      else
        STDERR.puts "#{source.id} lacks reference format"
        next
      end
      puts "Converting #{source.title}..."

      s_reference_fields = self.compute(source)

      source.source_divisions.each do |source_division|
        sd_reference_fields = self.compute(source_division, s_reference_fields)

        source_division.sentences.each do |sentence|
          sent_reference_fields = self.compute(sentence, sd_reference_fields)

          Sentence.transaction do
            sentence.tokens.each do |token|
              token.citation_part = self.compute(token, sent_reference_fields).inject(reference_format) do |s, (key, value)|
                case value
                when Range: value = [value.first, value.last].join("\u{2013}")
                when Integer, String: value = value.to_s
                when Array: value = value.join(', ')
                else
                  raise "Invalid reference_fields value #{value.inspect} for key #{key}"
                end

                s.gsub("##{key}#", value)
              end
              token.save_without_validation!
            end
          end
        end
      end
    end
  end

  def self.up
    rename_column :sources, :abbreviation, :citation_part
    add_column :tokens, :citation_part, :string, :limit => 64, :default => "", :null => false

    self.compute_citations

    remove_column :tokens, :reference_fields
    remove_column :sentences, :reference_fields
    remove_column :source_divisions, :reference_fields
    remove_column :sources, :reference_fields
    remove_column :sources, :reference_format
    remove_column :sources, :tracked_references

    remove_column :tokens, :verse
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
