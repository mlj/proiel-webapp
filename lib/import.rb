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

class PROIELXMLImporter
  SOURCE_ATTRS = %w(@language title author edition citation_part)

  SOURCE_DIVISION_ATTRS = %w(title abbreviation @presentation_before
                             @presentation_after)

  SENTENCE_ATTRS = %w(@presentation_before @presentation_after @status)

  TOKEN_ATTRS = %w(@morph_features @citation_part @relation @information_status
                   @contrast_group @empty_token_sort @form @presentation_before
                   @presentation_after)

  def set_attrs!(ar_obj, xml_obj, attrs)
    attrs.each { |attr| ar_obj.send(attr.sub('@', '') + '=', xml_obj[attr] }
  end

  def create_with_attrs!(klass, xml_obj, attrs, other_attrs = {})
    ar_obj = klass.new
    yield ar_obj
    other_attrs.each do |k, v|
      ar_obj.send(k, v)
    end
    set_attrs(ar_obj, xml_obj, attrs)
    ar_obj.save!
    ar_obj
  end

  # Reads import data. The data source +xml_or_file+ may be an opened
  # file or a string containing the XML.
  def read(xml_or_file)
    # Validate first so that we can assume that required elements/attributes are
    # present.
    `xmllint --path #{Proiel::Application.config.schema_file_path} --nonet --schema #{File.join(Proiel::Application.config.schema_file_path, schema_file_name)} --noout #{file_name}`

    # First grab the TEI headers verbatim
    doc = Nokogiri::XML(xml_or_file)
    tei_headers = (doc/:source).map { |source| (source/:"tei-header").to_s }

    # Then parse all the other stuff
    parser = Nori.new(:parser => :nokogiri)
    data = parser.parse(xml_or_file)['proiel']

    # Verify annotation scheme
    data['annotation']['relations'].each do |v|
      raise "undefined relation #{v}" unless RelationTag.include?(v)
    end

    data['annotation']['parts-of-speech'].each do |v|
      raise "undefined part of speech #{v}" unless PartOfSpeechTag.include?(v)
    end

    data['annotation']['information-statues'].each do |v|
      raise "undefined information status #{v}" unless InformationStatusTag.include?(v)
    end

    data['annotation']['morphology'] # TODO

    # Process sources
    [*data['source']].each do |source, source_position|
      Source.transaction do
        Source.disable_auditing
        SourceDivision.disable_auditing
        Sentence.disable_auditing
        Token.disable_auditing

        token_id_map = {} # map imported token IDs to database token IDs
        tei_header = tei_headers[source_position] # match the TEI header

        sr = create_with_attrs!(Source, source, SOURCE_ATTRS, :tei_header => tei_header)

        [*sr['div']].each_with_index do |div, div_position|
          sd = create_with_attrs!(source.source_divisions, div, SOURCE_DIVISION_ATTRS, :position => div_position)

          [*div['sentence']].each_with_index do |sentence, sentence_position|
            s = create_with_attrs!(sd.sentences, sentence, SENTENCE_ATTRS, :sentence_number => sentence_position)

            [*sentence['token']].each_with_index do |token, token_position|
              t = create_with_attrs!(s.tokens, token, TOKEN_ATTRS, :token_number => token_position)

              token_id_map[token['@id'].to_i] = t.id
            end

            # Make a second pass to set up head_id, antecedent_id and slashes.
            [*sentence['token']].each do |token|
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

                [*token['slash']].each do |slash|
                  target_id = slash['@target_id']
                  new_target_id = token_id_map[target_id.to_i]
                  raise "No slash target token #{target_id} found for token #{t.id}" unless new_target_id
                  t.slash_out_edges.create! :slashee_id => new_target_id, :relation => slash['relation']
                end

                t.save! if t.changed?
              end
            end
          end
        end
      end
    end
  end
end
