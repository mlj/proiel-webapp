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
