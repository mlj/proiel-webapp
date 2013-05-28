# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Dag Haug
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

require 'nori'

class PROIELXMLImporter < XMLSourceImporter
  def self.schema_file_name
    'proiel.xsd'
  end

  protected

  SOURCE_ATTRS = %w(@language title author edition citation_part)

  SOURCE_DIVISION_ATTRS = %w(title @presentation_before @presentation_after)

  SENTENCE_ATTRS = %w(@presentation_before @presentation_after)

  TOKEN_ATTRS = %w(@citation_part @relation @information_status
                   @contrast_group @empty_token_sort @form @presentation_before
                   @presentation_after)

  def set_attrs!(ar_obj, xml_obj, attrs)
    attrs.each { |attr| ar_obj.send("#{attr.sub('@', '')}=", xml_obj[attr]) }
  end

  def create_with_attrs!(klass, xml_obj, attrs, other_attrs = {})
    ar_obj = klass.new
    other_attrs.each do |k, v|
      ar_obj.send("#{k}=", v)
    end
    set_attrs!(ar_obj, xml_obj, attrs)
    ar_obj.save!
    ar_obj
  end

  def test_annotation_fields(container, tag_klass)
    container['field'].each do |v|
      test_annotation_values(v, tag_klass)
    end
  end

  def test_annotation_values(container, tag_klass)
    container['value'].each do |v|
      tag = v['@tag']
      raise "undefined relation #{tag}" unless tag_klass.include?(tag)
    end
  end

  def arrify(x)
    case x
    when Array
      x
    when NilClass
      []
    else
      [x]
    end
  end

  # Reads import data. The data source +xml_or_file+ may be an opened
  # file or a string containing the XML.
  def parse(file)
    # First grab the TEI headers verbatim
    doc = Nokogiri::XML(file)
    tei_headers = (doc/:source).map { |source| (source/:"tei-header").to_s }

    # Then parse all the other stuff
    parser = Nori.new(:parser => :nokogiri)
    file.rewind
    data = parser.parse(file.read)

    top_level = data['proiel']
    raise "unsupported PROIEL XML version" unless top_level['@schema_version'] == "1.0"

    # Verify annotation scheme
    annotation = top_level['annotation']

    if annotation
      test_annotation_values(annotation['relations'], RelationTag)
      test_annotation_values(annotation['parts_of_speech'], PartOfSpeechTag)
      test_annotation_values(annotation['information_statuses'], InformationStatusTag)
      # TODO: morphology
    end

    # Process sources
    arrify(top_level['source']).each_with_index do |source, source_position|
      Source.transaction do
        Source.disable_auditing
        SourceDivision.disable_auditing
        Sentence.disable_auditing
        Token.disable_auditing

        token_id_map = {} # map imported token IDs to database token IDs
        tei_header = tei_headers[source_position] # match the TEI header
        code = source['@id']

        sr = create_with_attrs!(Source, source, SOURCE_ATTRS,
                                :tei_header => tei_header,
                                :code => code)

        arrify(source['div']).each_with_index do |div, div_position|
          sd = create_with_attrs!(sr.source_divisions, div, SOURCE_DIVISION_ATTRS,
                                  :position => div_position)

          arrify(div['sentence']).each_with_index do |sentence, sentence_position|
            s = create_with_attrs!(sd.sentences, sentence, SENTENCE_ATTRS,
                                   :sentence_number => sentence_position,
                                   :status_tag => 'unannotated')

            arrify(sentence['token']).each_with_index do |token, token_position|
              t = create_with_attrs!(s.tokens, token, TOKEN_ATTRS,
                                     :token_number => token_position)

              if token['@lemma'] or token['part_of_speech'] or token['@morphology']
                t.morph_features = MorphFeatures.new("#{token['@lemma']},#{token['@part_of_speech']},#{sr.language_tag}", token['@morphology'])
              end

              token_id_map[token['@id'].to_i] = t.id
            end

            # Make a second pass to set up head_id, antecedent_id and slashes.
            arrify(sentence['token']).each do |token|
              head_id = token['@head_id']
              antecedent_id = token['@antecedent_id']

              if head_id or antecedent_id or token['slash']
                t = Token.find(token_id_map[token['@id'].to_i])

                if head_id
                  new_head_id = token_id_map[head_id.to_i]
                  raise "No head token #{head_id} found for token #{t.id}" unless new_head_id
                  t.head_id = new_head_id
                end

                if antecedent_id
                  new_antecedent_id = token_id_map[antecedent_id.to_i]
                  raise "No antecedent token #{antecedent_id} found for token #{t.id}" unless new_antecedent_id
                  t.antecedent_id = new_antecedent_id
                end

                arrify(token['slash']).each do |slash|
                  target_id = slash['@target_id']
                  new_target_id = token_id_map[target_id.to_i]
                  raise "No slash target token #{target_id} found for token #{t.id}" unless new_target_id
                  t.slash_out_edges.create! :slashee_id => new_target_id, :relation_tag => slash['@relation']
                end

                t.save! if t.changed?
              end
            end

            # Finally, set the correct sentence status, which may trigger
            # validation of annotation
            set_attrs!(s, sentence, ['@status']) if sentence['@status']
            s.save!
          end
        end
      end
    end
  end
end
