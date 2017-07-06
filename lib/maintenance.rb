require 'csv'

module Proiel::Maintenance
  class CSVWriter
    def initialize(filename)
      @f = File.open(filename, 'w')
    end

    def write(*args)
      args = args.first if args.length and args.first.is_a?(Array)
      @f.puts args.to_csv
    end

    def close
      @f.close
    end
  end

  def self.import_csv(filename, &block)
    raise ArgumentError, 'filename expected' unless filename.is_a?(String)
    raise ArgumentError, 'file not found' unless File.exists?(filename)

    wrap_status("Importing #{filename}") do
      Token.transaction do
        CSV.foreach(filename, headers: true) do |row|
          yield OpenStruct.new(row.to_h.map { |k, v| [k.downcase, v] }.to_h)
        end
      end

      true
    end
  end

  def self.export_csv(filename, headers, &block)
    raise ArgumentError, 'filename expected' unless filename.is_a?(String)
    raise ArgumentError, 'file already exists' if File.exists?(filename)

    wrap_status("Exporting #{filename}") do
      f = CSVWriter.new(filename)
      f.write headers
      block.call(f)
      f.close

      true
    end
  end

  def self.wrap_status(msg, &block)
    STDOUT.write "#{msg}..."
    block.call.tap do |result|
      STDOUT.puts result ? " OK".green : " Failed".red
    end
  rescue RuntimeError => e
    STDOUT.puts " Failed".red
    STDERR.puts e

    false
  end

  module Texts
    def self.import(filename)
      raise ArgumentError, 'filename expected' unless filename.is_a?(String)
      raise ArgumentError, 'file not found' unless File.exists?(filename)

      valid =
        Proiel::Maintenance.wrap_status("Validating #{filename}") do
          v = PROIEL::PROIELXML::Validator.new(filename)
          v.valid?
        end

      if valid
        id_map_filename = nil #FIXME

        Proiel::Maintenance.wrap_status("Importing #{filename}") do
          i = PROIELXMLImporter.new
          i.read(filename, id_map_file: id_map_filename)

          true
        end
      end
    end

    def self.export(id = nil, filename = nil)
      if id.nil?
        Source.all.each { |s| self.export(s.id, filename) }
      elsif filename.nil?
        source = Source.find(id)
        self.export(id, source.code + '.xml')
      else
        raise ArgumentError, 'source ID expected' unless id.is_a?(String) or id.is_a?(Numeric)
        raise ArgumentError, 'filename expected' unless filename.is_a?(String)
        raise ArgumentError, 'file already exists' if File.exists?(filename)

        source = Source.find(id)

        Proiel::Maintenance.wrap_status("Exporting #{filename}") do
          e = PROIELXMLExporter.new(source)
          e.write(filename)

          true
        end
      end
    end
  end

  module DependencyAlignments
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting dependency alignments") do
        Token.update_all(dependency_alignment_id: nil)
        DependencyAlignmentTerm.delete_all
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(ID DEPENDENCY_ALIGNMENT_ID DEPENDENCY_ALIGNMENT_TERMINATION_IDS)) do |f|
        Token.
          joins(:dependency_alignment_terminations).
          where('dependency_alignment_id IS NOT NULL OR dependency_alignment_terms.source_id IS NOT NULL').find_each do |o|
          f.write o.id, o.dependency_alignment_id, o.dependency_alignment_terminations.all.map(&:source_id).join(',')
        end
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        t = Token.find(o.id)
        t.dependency_alignment_id = o.dependency_alignment_id

        o.dependency_alignment_termination_ids.split(',').each do |source_id|
          DependencyAlignmentTerm.create! token_id: o.id, source_id: source_id
        end
      end
    end
  end

  module SemanticRelations
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting semantic relations") do
        SemanticRelation.delete_all
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        type = SemanticRelationType.find_by_tag(o.semantic_relation_type_tag)
        raise "Unknown semantic relation type #{o.semantic_relation_type_tag}" unless type

        tag = SemanticRelationTag.find_by_tag(o.semantic_relation_tag)
        raise "Unknown semantic relation tag #{o.semantic_relation_tag}" unless tag

        raise "The semantic relation tag #{o.semantic_relation_tag} has the wrong type #{tag.semantic_relation_type.tag} != #{type.tag}" unless tag.semantic_relation_type == type
        raise "No controller of id #{o.controller_id} found" unless Token.find(o.controller_id)
        raise "No target of id #{o.target_id} found" unless Token.find(o.target_id)

        s = SemanticRelation.new
        s.controller_id = o.controller_id
        s.target_id = o.target_id
        s.semantic_relation_tag = tag
        s.save!
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(SEMANTIC_RELATION_TYPE_TAG SEMANTIC_RELATION_TAG CONTROLLER_ID TARGET_ID)) do |f|
        SemanticRelation.find_each do |o|
          # FIXME: This situation should be prevented by database constraints
          if o.controller and o.target
            f.write o.semantic_relation_type.tag, o.semantic_relation_tag.tag, o.controller_id, o.target_id
          else
            STDERR.puts "Ignoring semantic relation #{o.id} since it references a missing controller or target token"
          end
        end
      end
    end
  end

  module SemanticTags
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting semantic tags") do
        SemanticTag.delete_all
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        attribute = SemanticAttribute.find_by_tag(o.attribute_tag)
        raise "Unknown attribute #{o.attribute_tag}" unless attribute

        value = attribute.semantic_attribute_values.find_by_tag(o.value_tag)
        raise "Unknown attribute value #{o.value_tag}" unless value

        klass =
          case o.taggable_type
          when "Token"
            Token
          when "Lemma"
            Lemma
          when "Sentence"
            Sentence
          else
            raise "Invalid taggable type #{taggable_type}"
          end

        taggable = klass.find(o.taggable_id)
        raise "Unknown taggable #{o.taggable_type} #{o.taggable_id}" unless taggable

        taggable.semantic_tags.create(semantic_attribute_value: value)
        taggable.save!
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(TAGGABLE_TYPE TAGGABLE_ID ATTRIBUTE_TAG VALUE_TAG)) do |f|
        SemanticTag.find_each do |o|
          # FIXME: May produce garbage if tangling taggable objects
          if o.taggable
            f.write o.taggable_type, o.taggable_id, o.semantic_attribute_value.semantic_attribute.tag, o.semantic_attribute_value.tag
          else
            STDERR.puts "Ignoring semantic tag #{o.id} since it references a missing object"
          end
        end
      end
    end
  end

  module TokenAlignments
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting token alignments") do
        Token.update_all token_alignment_id: nil, automatic_token_alignment: false
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        t = Token.find(o.id)
        t.update_attributes! token_alignment_id: o.token_alignment_id, automatic_token_alignment: o.automatic_token_alignment
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(ID TOKEN_ALIGNMENT_ID AUTOMATIC_TOKEN_ALIGNMENT)) do |f|
        Token.where('token_alignment_id IS NOT NULL').find_each do |o|
          f.write o.id, o.token_alignment_id, o.automatic_token_alignment
        end
      end
    end
  end

  module Notes
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting notes") do
        Note.delete_all
      end

      Proiel::Maintenance.wrap_status("Optimising database tables") do
        ActiveRecord::Base.connection.execute('OPTIMIZE TABLE notes')
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        Note.create!(originator_type: o.originator_type,
                     originator_id: o.originator_id,
                     notable_type: o.notable_type,
                     notable_id: o.notable_id,
                     contents: o.contents)
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(ORIGINATOR_TYPE ORIGINATOR_ID NOTABLE_TYPE NOTABLE_ID CONTENTS)) do |f|
        Note.find_each do |o|
          f.write o.originator_type, o.originator_id, o.notable_type, o.notable_id, o.contents
        end
      end
    end
  end

  module InformationStatuses
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting information statuses") do
        Token.
          where(empty_token_sort: 'P').
          delete_all

        Token.
          where('information_status_tag IS NOT NULL OR antecedent_id IS NOT NULL').
          update_all information_status_tag: nil, antecedent_id: nil
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        antecedent_id =
          if o.antecedent_id
            o.antecedent_id
          elsif o.antecedent_head_id and o.antecedent_relation_tag
            s = Token.find(o.antecedent_head_id)
            s.sentence.append_new_token!(head_id: o.antecedent_head_id,
                                         relation_tag: o.antecedent_relation_tag,
                                         empty_token_sort: 'P').id
          else
            nil
          end

        if o.id
          t = Token.find(o.id)
          t.update_attributes!(information_status_tag: o.information_status_tag,
                               antecedent_id: antecedent_id)
        else
          s = Token.find(o.head_id)
          s.sentence.append_new_token!(head_id: o.head_id,
                                       relation_tag: o.relation_tag,
                                       empty_token_sort: 'P',
                                       information_status_tag: o.information_status_tag,
                                       antecedent_id: antecedent_id)
        end
      end
    end

    private

    def self._grab_fields(o)
      {}.tap do |fields|
        if o.nil?
        elsif o.empty_token_sort == 'P'
          fields[:head_id] = o.head_id
          fields[:relation_tag] = o.relation_tag
        else
          fields[:id] = o.id
        end
      end
    end

    public

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(ID HEAD_ID RELATION_TAG INFORMATION_STATUS_TAG ANTECEDENT_ID ANTECEDENT_HEAD_ID ANTECEDENT_RELATION_TAG)) do |f|
        Token.where('information_status_tag IS NOT NULL OR antecedent_id IS NOT NULL').find_each do |o|
          of = _grab_fields(o)
          af = _grab_fields(o.antecedent)

          f.write of[:id], of[:head_id], of[:relation_tag], o.information_status_tag, af[:id], af[:head_id], af[:relation_tag]
        end
      end
    end
  end

  module History
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting history") do
        Audited::Adapters::ActiveRecord::Audit.delete_all
      end

      Proiel::Maintenance.wrap_status("Optimising database tables") do
        ActiveRecord::Base.connection.execute('OPTIMIZE TABLE audits')
      end
    end
  end

  module Morphology
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting morphology") do
        Token.
          update_all lemma_id: nil, morphology_tag: nil
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        t = Token.find(o.id)
        t.update_attributes! lemma_id: o.lemma_id, morphology_tag: o.morphology_tag
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(ID LEMMA_ID MORPHOLOGY_TAG)) do |f|
        Token.where('morphology_tag IS NOT NULL OR lemma_id IS NOT NULL').find_each do |o|
          f.write o.id, o.lemma_id, o.morphology_tag
        end
      end
    end
  end

  module Inflections
    def self.delete
      Proiel::Maintenance.wrap_status("Deleting inflections") do
        Inflection.delete_all
      end

      Proiel::Maintenance.wrap_status("Optimising database tables") do
        ActiveRecord::Base.connection.execute('OPTIMIZE TABLE inflections')
      end
    end

    def self.import(filename)
      Proiel::Maintenance.import_csv(filename) do |o|
        Inflection.create!(language_tag: o.language_tag,
                           form: o.form,
                           lemma: o.lemma,
                           part_of_speech_tag: o.part_of_speech_tag,
                           morphology_tag: o.morphology_tag)
      end
    end

    def self.export(filename)
      Proiel::Maintenance.export_csv(filename, %w(LANGUAGE_TAG FORM LEMMA PART_OF_SPEECH_TAG FORM MORPHOLOGY_TAG)) do |f|
        Inflection.find_each do |o|
          f.write o.language_tag, o.form, o.lemma, o.part_of_speech_tag, o.form, o.morphology_tag
        end
      end
    end
  end
end
