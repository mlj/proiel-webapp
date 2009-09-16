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

class InfoStatusesImportExport < CSVImportExport
  def initialize(sd = nil)
    @sd = SourceDivision.find(sd)
    super :token, :info_status, :antecedent
  end

  protected

  def read_fields(token, info_status, antecedent)
    # prodrop
    if token =~ /\+/
      head_id, relation = token.split(/\+/)
      s = Sentence.find(Token.find(head_id).sentence_id)
      tts =  s.tokens.find(:all, :conditions => [ "head_id = ? and relation_id = ?", head_id, Relation.find_by_tag(relation).id ] )
      case tts.size
      when 0
        t = create_prodrop_relation(s, "new3", relation, head_id)
      when 1
        t = tts.last
      else
        raise "Several candidates! #{token} could refer to all of #{tts.map(&:id).join(",")} "
      end
    else
      t = Token.find(token.to_i)
    end

    t.info_status = info_status
    t.save!

    if antecedent != "" and antecedent != "missing"
      unless antecedent =~ /\+/
        ac = Token.find(antecedent)
      else
        head_id, relation = antecedent.split(/\+/)
        s2 = Token.find(head_id).sentence
        acs = s2.tokens.find(:all, :conditions => [ "head_id = ? and relation_id = ?", head_id, Relation.find_by_tag(relation).id ])
        case acs.size
        when 0
          ac = create_prodrop_relation(s2, "new3", relation, head_id)
        when 1
          ac = acs.last
        else
          raise "Antecedent problems"
        end
      end
      t.antecedent_id = ac.id
      t.antecedent_dist_in_words = Token.word_distance_between(ac, t)
      t.antecedent_dist_in_sentences = Token.sentence_distance_between(ac, t)
      t.save!
    end
  end

  def create_prodrop_relation(sentence, prodrop_id, relation, verb_id, info_status = nil)
    graph = sentence.dependency_graph
    verb_node = graph[verb_id]
    verb_token = Token.find(verb_id)
    graph.add_node(prodrop_id, relation, verb_token.id)
    sentence.syntactic_annotation = graph

    # syntactic_annotation= will have created a token at the end of the sentence
    prodrop_token = Token.find(sentence.tokens.last.id)
    prodrop_token.verse = verb_token.verse
    prodrop_token.form = nil
    prodrop_token.info_status = info_status
    prodrop_token.empty_token_sort = 'P'
    prodrop_token.save!

    # This is apparently needed after saving a new graph node to the database in order to make
    # sure that the new node is included in the dependency_tokens collection. Otherwise,
    # the node will be deleted the next time we run syntactic_annotation= (e.g., if we try to
    # create more than one prodrop token as part of the same save operation).
    sentence.dependency_tokens.reload

    prodrop_token
  end

  def write_fields
    conditions = if @sd
                   ["info_status is not null and info_status != 'info_unannotatable' and sentence_id in (?)", @sd.sentences]
                 else
                   ["info_status is not null and info_status != 'info_unannotatable'"]
                 end
    Token.find(:all, :conditions => conditions).each do |t|
      case t.empty_token_sort
      when "P"
        token = "#{t.head.id}+#{t.relation.tag}"
      else
        token = t.id.to_s
      end
      info_status = t.info_status
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

      yield token, info_status, antecedent
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
    super :language_code, :lemma, :variant, :pos, :form, :morphologies
  end

  protected

  def read_fields(language_code, lemma, pos, form, *morphologies)
    @language = Language.find_by_iso_code(language_code) if @language_code != language_code

    morphologies.each do |morphology|
      @language.inflections.create!(:morphology => morphology,
                                    :form => form,
                                    :lemma => [lemma, pos].join(','))
    end
  end

  def write_fields
    Inflection.find_each do |inflection|
      lemma, pos = inflection.lemma.split(/,/)
      yield inflection.language.iso_code, lemma, pos, inflection.form, inflection.morphology
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
