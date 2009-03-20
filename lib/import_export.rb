#!/usr/bin/env ruby
#
# import_export.rb - Import and export functions
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# Abstract importer for CSV files.
class CSVImportExport
  def initialize(*fields)
    @fields = fields
  end

  def read(file_name)
    raise "Import not supported" unless respond_to?(:read_fields)

    Token.transaction do
      File.open(file_name) do |f|
        f.each_line do |l|
          values = l.chomp.gsub(/#.*$/, '').split(/\s*,\s*/, @fields.length)
          next if values.length.zero? # skip empty lines and commented lines
          read_fields(*values)
        end
      end
    end
  end

  def write(file_name)
    raise "Export not supported" unless respond_to?(:write_fields)

    File.open(file_name, 'w') do |f|
      write_fields do |*values|
        raise "Invalid number of fields" unless values.length == @fields.length
        f.puts values.join(",")
      end
    end
  end
end

# Importer for dependency alignments
class DependencyAlignmentImportExport < CSVImportExport
  def initialize
    super :operation, :primary_token, :secondary_token
  end

  protected

  def read_fields(operation, primary_token, secondary_token)
    case operation
    when 'ALIGN'
      t1 = Token.find(primary_token)
      raise "Unable to find primary token with ID #{primary_token}" unless t1

      t2 = Token.find(secondary_token)
      raise "Unable to find secondary token with ID #{secondary_token}" unless t2

      # FIXME: this is wrong. *Sentences* have to be aligned for this
      # to work. Actually, it's even worse: the sentences that the two
      # tokens belong to have to be part of the same sentence alignment
      # group.

      # t2 is the secondary source for alignment, thus the one with
      # aligned_source_division set.
      raise "Source division #{t1.sentence.source_division.id} and #{t2.sentence.source_division.id} for tokens #{t1.id} and #{t2.id} are not aligned" unless t2.sentence.source_division.aligned_source_division == t1.sentence.source_division

      t2.dependency_alignment = t1
      t2.save!

    when 'TERMINATE'
      # This is an 'alignment termination'.
      t = Token.find(primary_token)
      raise "Unable to find termination token with ID #{primary_token}" unless t

      s = Source.find(secondary_token)
      raise "Unable to find termination target sourcewith ID #{secondary_token}" unless s

      t.dependency_alignment_terminations.create!(:source => s)
    else
      raise "Invalid operation #{operation}"
    end
  end
end

# Importer for inflections
class InflectionsImportExport < CSVImportExport
  def initialize
    super :language_code, :lemma, :variant, :form, :morphtag
  end

  protected

  def read_fields(language_code, lemma, variant, form, *morphtags)
    @language = Language.find_by_iso_code(language_code) if @language_code != language_code

    morphtags = morphtags.map { |morphtag| PROIEL::MorphTag.new(morphtag) }
    raise "invalid morphtag for form #{form}" unless morphtags.all? { |m| m.is_valid?(language_code) }

    morphtags.map(&:to_s).each do |morphtag|
      @language.inflections.create!(:morphtag => morphtag,
                                    :form => form,
                                    :lemma => variant.blank? ? lemma : "#{lemma}##{variant}")
    end
  end

  def write_fields
    Inflection.find_each do |inflection|
      lemma, variant = inflection.lemma.split(/#/)
      yield inflection.language.iso_code, lemma, variant, inflection.form, inflection.morphtag
    end
  end
end

# Importer for semantic tags
class SemanticTagImportExport < CSVImportExport
  def initialize
    super :taggable_type, :taggable_id, :attribute_tag, :value_tag
  end

  protected

  def read_fields(taggable_type, taggable_id, attribute_tag, value_tag)
    attribute = SemanticAttribute.find_by_tag(attribute_tag)
    raise "Unknown attribute #{attribute_tag}" unless attribute
    value = attribute.semantic_attribute_values.find_by_tag(value_tag)
    raise "Unknown attribute value #{value_tag}" unless value

    case taggable_type
    when "Token"
      klass = Token
    when "Lemma"
      klass = Lemma
    else
      raise "Invalid taggable type #{taggable_type}"
    end

    taggable = klass.find(taggable_id)
    raise "Unknown taggable #{taggable_type} #{taggable_id}" unless taggable

    taggable.semantic_tags.create(:semantic_attribute_value => value)
    taggable.save!
  end

  def write_fields
    SemanticTag.find(:all).each do |tag|
      yield tag.taggable_type, tag.taggable_id, tag.semantic_attribute_value.semantic_attribute.tag, tag.semantic_attribute_value.tag
    end
  end
end
