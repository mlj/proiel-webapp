# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Dag Haug
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Marius L. Jøhndal
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

require 'singleton'
require 'nokogiri'

class TextImport
  include Singleton

  # Reads import data. The data source +xml_or_file+ may be an opened
  # file or a string containing the XML.
  def read(xml_or_file)
    doc = Nokogiri::XML(xml_or_file)

    identifier = (doc/:source).first.attributes['id'].to_s
    language = (doc/:source).first.attributes['language'].to_s
    STDERR.puts "Importing source #{identifier} (#{language})"

    Source.transaction do
      source = Source.find_by_code(identifier)

      unless source
        # There may be elements called 'title', 'abbreviation' etc
        # elsewhere (typically inside the TEI header), so we must be
        # careful to get only the children of 'source'.
        title = doc.search('source > title').inner_html
        abbreviation = doc.search('source > abbreviation').inner_html
        tei_header = (doc/:source/:"tei-header").to_s
        source = Source.create!(:code => identifier,
                              :language => language,
                              :title => title,
                              :citation_part => abbreviation,
                              :tei_header => tei_header)
      end

      # We do not need versioning for imports, so disable it.
      Sentence.disable_auditing
      Token.disable_auditing

      # we need to keep track of tokens in the whole source because of anaphoric relations
      token_id_map = {}

      (doc/:div).each_with_index do |div, div_position|
        # TODO: potential problem here if user imports another bit of the same
        # source, then div_position will be too low.
        sd = source.source_divisions.create! :position => div_position,
          :title => (div/:title).inner_html,
          :abbreviated_title => (div/:abbreviation).inner_html

        # TODO: remove this and make a separate importer for unsegmented text
        unless (div/:"unsegmented-text").empty?
          (div/:"unsegmented-text").inner_html.chomp.gsub(/\s+/, ' ').gsub(/(\s*[—]?[\.\?:\!][—]?)\s+/, '\1#').split(/#/).map(&:chomp).each_with_index do |segment, segment_position|
            add_sentence(sd, segment_position, segment)
          end
        else
          (div/:sentence).each_with_index do |sentence, sentence_position|
            s = sd.sentences.new
            s.sentence_number = sentence_position
            s.presentation_before = sentence.attributes['presentation-before'].to_s unless sentence.attributes['presentation-before'].nil? or sentence.attributes['presentation-before'].empty?
            s.presentation_after = sentence.attributes['presentation-after'].to_s unless sentence.attributes['presentation-after'].nil? or sentence.attributes['presentation-after'].empty?
            s.save!

            # Set up the token data.
            (sentence/:token).each_with_index do |token, token_position|
              t = s.tokens.new

              t.form = token.attributes['form'].to_s unless token.attributes['form'].try(:to_s).blank?
              t.empty_token_sort = token.attributes['empty-token-sort'].to_s unless token.attributes['empty-token-sort'].try(:to_s).blank?
              t.foreign_ids = token.attributes['foreign-ids'].to_s unless token.attributes['foreign-ids'].try(:to_s).blank?
              t.token_number = token_position
              t.citation_part = token.attributes['citation-part'].to_s unless token.attributes['citation-part'].try(:to_s).blank?
              t.presentation_before = token.attributes['presentation-before'].to_s unless token.attributes['presentation-before'].nil? or token.attributes['presentation-before'].to_s.empty?
              t.presentation_after = token.attributes['presentation-after'].to_s unless token.attributes['presentation-after'].nil? or token.attributes['presentation-after'].to_s.empty?
              t.info_status = token.attributes['info-status'].to_s unless token.attributes['info-status'].try(:to_s).blank?
              t.morph_features = token.attributes['morph-features'].to_s unless token.attributes['morph-features'].try(:to_s).blank?
              t.source_morph_features = token.attributes['source-morph-features'].to_s unless token.attributes['source-morph-features'].try(:to_s).blank?

              t.save!

              token_id_map[token.attributes['id'].to_s.to_i] = t.id
            end

            # Make another pass to set up dependencies and antecedents
            (sentence/:token).each_with_index do |token, token_position|
              t = Token.find(token_id_map[token.attributes['id'].to_s.to_i])
              raise "No head #{token.attributes['head-id'].to_s} found for #{t.id}" if token.attributes['head-id'] and !token_id_map[token.attributes['head-id'].to_s.to_i]
              t.head_id = token_id_map[token.attributes['head-id'].to_s.to_i] if token.attributes['head-id']
              raise "No antecedent #{token.attributes['antecedent-id'].to_s} found for #{t.id}" if token.attributes['antecedent-id'] and !token_id_map[token.attributes['antecedent-id'].to_s.to_i]
              t.antecedent_id = token_id_map[token.attributes['antecedent-id'].to_s.to_i] if token.attributes['antecedent-id']
              t.relation = Relation.find_by_tag(token.attributes['relation'].to_s) if token.attributes['relation']
              t.save! if t.changed?
              (token/:slashes/:slash).each do |slash|
                t.slash_out_edges.create! :slashee_id => token_id_map[slash.attributes['target'].to_s.to_i],
                                  :relation_id => Relation.find_by_tag(slash.attributes['label'].to_s).id
              end
            end

            (sentence/:note).each do |note|
              originator = ImportSource.find_or_create_by_tag :tag => note.attributes['originator'].to_s,
                :summary => note.attributes['originator'].to_s

              s.notes.create! :contents => note.inner_html,
                :originator => originator
            end
            # Import status information
            status = sentence.attributes['status'].to_s
            if status == 'reviewed'
              s.annotated_at = Time.now
              s.reviewed_at = Time.now
              s.save!
            elsif status == 'annotated'
              s.annotated_at = Time.now
              s.save!
            end
          end
        end
      end
    end
  end

  private

  def add_sentence(sd, position, presentation)
    sd.sentences.new(:sentence_number => position,
                     :presentation => presentation).tap do |s|
      # TODO: citation
    end
  end
end
