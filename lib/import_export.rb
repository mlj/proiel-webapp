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
    raise "Import not supported" unless respond_to?(:read_fields, true)

    Token.transaction do
      File.open(file_name) do |f|
        f.each_line do |l|
          values = l.chomp.split(/\s*,\s*/, @fields.length)
          next if values.length.zero? # skip empty lines and commented lines
          read_fields(*values)
        end
      end
    end
  end

  def write(file_name)
    raise "Export not supported" unless respond_to?(:write_fields, true)

    File.open(file_name, 'w') do |f|
      write_fields do |*values|
        raise "Invalid number of fields" unless values.length == @fields.length
        f.puts values.join(",")
      end
    end
  end
end

class NoteImportExport < CSVImportExport
  def initialize
    super :originator_type, :originator_id, :notable_type, :notable_id, :contents
  end

  protected

  def read_fields(originator_type, originator_id, notable_type, notable_id, contents)
    Note.create!(:originator_type => originator_type,
                 :originator_id => originator_id,
                 :notable_type => notable_type,
                 :notable_id => notable_id,
                 :contents => contents)
  end
end

class TokenAlignmentImportExport < CSVImportExport
  def initialize
    super :token_id, :token_alignment_id, :automatic_token_alignment
  end

  def read_fields(token_id, token_alignment_id, automatic_token_alignment)
    t = Token.find(token_id)
    t.token_alignment = Token.find(token_alignment_id)
    # for some reason this line is needed to make rails find the set method in the following line
    t.automatic_token_alignment 
    t.automatic_token_alignment = false unless automatic_token_alignment == "true"
    t.save!
  end

  def write_fields
    Token.find_each(:conditions => "token_alignment_id IS NOT NULL") do |t|
      yield t.id, t.token_alignment_id, t.automatic_token_alignment
    end
  end
end


class InfoStatusesImportExport < CSVImportExport
  def initialize(sd = nil)
    @sd = (sd ? SourceDivision.find(sd) : nil)
    super :token, :information_status, :antecedent
  end

  protected

  def read_fields(token, information_status, antecedent)
    # prodrop
    if token =~ /\+/
      head_id, relation = token.split(/\+/)
      s = Sentence.find(Token.find(head_id).sentence_id)
      tts =  s.tokens.find(:all, :conditions => [ "head_id = ? and relation_tag = ?", head_id, relation ] )
      case tts.size
      when 0
        t = create_prodrop_relation(s, relation, head_id)
      when 1
        t = tts.last
      else
        raise "Several candidates! #{token} could refer to all of #{tts.map(&:id).join(",")} "
      end
    else
      t = Token.find(token.to_i)
    end

    t.information_status_tag = information_status
    t.save!

    if antecedent != "" and antecedent != "missing"
      unless antecedent =~ /\+/
        ac = Token.find(antecedent)
      else
        head_id, relation = antecedent.split(/\+/)
        s2 = Token.find(head_id).sentence
        acs = s2.tokens.find(:all, :conditions => [ "head_id = ? and relation_tag = ?", head_id, relation ])
        case acs.size
        when 0
          ac = create_prodrop_relation(s2, relation, head_id)
        when 1
          ac = acs.last
        else
          raise "Antecedent problem: token #{head_id} has more than one #{relation.tag}"
        end
      end
      t.antecedent_id = ac.id
      t.save!
    end
  end

  def create_prodrop_relation(sentence, relation, verb_id, information_status = nil)
    sentence.append_new_token!(
                               :head_id => verb_id,
                               :relation => relation,
                               :empty_token_sort => 'P',
                               :information_status_tag => information_status).tap do

      # This is needed after saving a new graph node to the database
      # in order to make sure that the new node is included in the
      # tokens.takes_syntax collection. Otherwise, the node
      # will be deleted the next time we run syntactic_annotation=
      # (e.g., if we try to create more than one prodrop token as part
      # of the same save operation).
      sentence.tokens.reload
    end
  end

  def write_fields
    conditions = if @sd
                   ["information_status_tag is not null and information_status_tag != 'info_unannotatable' and sentence_id in (?)", @sd.sentences]
                 else
                   ["information_status_tag is not null and information_status_tag != 'info_unannotatable'"]
                 end
    Token.find(:all, :conditions => conditions).each do |t|
      case t.empty_token_sort
      when "P"
        token = "#{t.head.id}+#{t.relation.tag}"
      else
        token = t.id.to_s
      end
      information_status = t.information_status_tag
      if t.antecedent_id
        ac = Token.find(t.antecedent_id)
        case ac.empty_token_sort
        when "P"
          antecedent = "#{ac.head.id}+#{ac.relation.tag}"
        else
          antecedent = ac.id.to_s
        end
      else
        antecedent = nil
      end

      yield token, information_status, antecedent
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
    super :language, :lemma, :pos, :form, :morphologies
  end

  protected

  def read_fields(language, lemma, pos, form, *morphologies)
    morphologies.each do |morphology|
      n = MorphFeatures.new([lemma, pos, language].join(","), morphology)
      if n.valid?
        begin
          Inflection.create!(morphology_tag: morphology,
                             language_tag: language,
                             form: form,
                             lemma: lemma,
                             part_of_speech_tag: pos)
        rescue
          STDERR.puts "Disregarding rule #{form} -> #{lemma},#{pos},#{n.morphology_summary}: #{$!}"
        end
      else
        STDERR.puts "The tag #{pos + morphology} -- #{n.morphology_summary} -- (assumed for #{form}) is invalid in language #{@language}...ignoring"
      end
    end
  end

  def write_fields
    Inflection.find_each do |inflection|
      yield inflection.language_tag,
        inflection.lemma,
        inflection.part_of_speech_tag,
        inflection.form,
        inflection.morphology_tag
    end
  end
end

class SemanticRelationImportExport < CSVImportExport
  def initialize
    super :type, :tag, :controller, :target
  end

  protected

  def read_fields(typus, taggus, controller_id, target_id)
    type = SemanticRelationType.find_by_tag(typus)
    raise "Unknown semantic relation type #{typus}" unless type
    tag = SemanticRelationTag.find_by_tag(taggus)
    raise "Unknown semantic relation tag #{taggus}" unless tag
    raise "The semantic relation tag #{taggus} has the wrong type #{tag.semantic_relation_type.tag} != #{type.tag}" unless tag.semantic_relation_type == type
    raise "No controller of id #{controller_id} found" unless Token.find(controller_id)
    raise "No target of id #{target_id} found" unless Token.find(target_id)
    SemanticRelation.create!(:controller_id => controller_id, :target_id => target_id, :semantic_relation_tag => tag)
  end

  def write_fields
    SemanticRelation.find(:all).each do |rel|
      yield rel.semantic_relation_type.tag, rel.semantic_relation_tag.tag, rel.controller_id, rel.target_id
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
    when "Sentence"
      klass = Sentence
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
