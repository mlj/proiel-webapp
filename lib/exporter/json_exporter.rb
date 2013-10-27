# encoding: UTF-8
#--
#
# Copyright 2013 University of Oslo
# Copyright 2013 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

class JSONExporter < SourceExporter
  def initialize(source, options = {})
    super

    @referenced_objects = {
      Lemma => [], User => [], Note => [], SemanticTag => [], SlashEdge => [], SemanticRelation => []
      # TODO:Lemma, Note, SemanticRelation, SemanticTag
      # Lemma
      #has_many :semantic_tags, :as => :taggable, :dependent => :destroy
    }
  end

  protected

  def write_toplevel!(file)
    yield file

    @referenced_objects.each do |klass, ids|
      klass.where(:id => ids.sort.uniq).find_each do |obj|
        write_model_object!(file, obj)
      end
    end
  end

  def write_source!(file, obj)
    write_model_object!(file, obj)

    yield file
  end

  def write_source_division!(file, obj)
    write_model_object!(file, obj)

    yield file
  end

  def write_sentence!(file, obj)
    write_model_object!(file, obj)

    obj.notes.each do |note|
      @referenced_objects[Note] << note.id
    end

    obj.semantic_tags.each do |semantic_tag|
      @referenced_objects[SemanticTag] << semantic_tag.id
    end

    yield file

    @referenced_objects[User] << obj.annotated_by if obj.annotated_by
    @referenced_objects[User] << obj.reviewed_by if obj.reviewed_by
    @referenced_objects[User] << obj.assigned_to if obj.assigned_to
  end

  def write_token!(file, obj)
    write_model_object!(file, obj)

    obj.notes.each do |note|
      @referenced_objects[Note] << note.id
    end

    obj.semantic_tags.each do |semantic_tag|
      @referenced_objects[SemanticTag] << semantic_tag.id
    end

    obj.slash_out_edges.each do |slash_edge|
      @referenced_objects[SlashEdge] << slash_edge.id
    end

    obj.outgoing_semantic_relations.each do |semantic_relation|
      @referenced_objects[SemanticRelation] << semantic_relation.id
    end

    @referenced_objects[Lemma] << obj.lemma_id if obj.lemma_id
  end

  private

  SUPPORTED_ATTRIBUTES = %w(id source_id source_division_id sentence_id head_id
                            antecedent_id slasher_id slashee_id lemma_id
                            annotated_by reviewed_by reviewed_at assigned_to form
                            token_number created_at updated_at foreign_ids title
                            citation_part language_tag position sentence_number
                            annotated_at status_tag relation_tag morphology_tag
                            presentation_after presentation_before
                            information_status_tag contrast_group
                            empty_token_sort lemma part_of_speech_tag
                            gloss variant unalignable automatic_alignment
                            login email last_name first_name automatic_token_alignment
                            tei_header author edition
                            source_morphology_tag source_lemma
                            contents notable_type notable_id
                           )

  WARNINGS_EMITTED = %w(encrypted_password password_salt confirmed_at
                        preferences remember_created_at sign_in_count reset_password_token confirmation_sent_at
                        current_sign_in_at last_sign_in_at current_sign_in_ip
                        last_sign_in_ip failed_attempts role)

  def write_model_object!(file, obj)
    attrs = obj.attributes.reject { |k, v| v.nil? or v == '' }.select do |k,v |
      if v.nil? or v == ''
        false
      elsif SUPPORTED_ATTRIBUTES.include?(k)
        true
      else
        unless WARNINGS_EMITTED.include?(k)
          STDERR.puts "Warning: Exporting #{k} is not supported. Attribute will be removed from export."
          WARNINGS_EMITTED << k
        end

        false
      end
    end

    file.puts({ obj.class => attrs }.to_json)
  end
end
