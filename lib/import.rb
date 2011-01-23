#--
#
# Copyright 2007, 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
require 'proiel/src'
require 'singleton'
require 'nokogiri'

class TextImport
  include Singleton

  # Reads import data. The data source +xml_or_file+ may be an opened
  # file or a string containing the XML.
  def read(xml_or_file)
    doc = Nokogiri::XML(xml_or_file)

    identifier = (doc/:source).first.attributes['id']
    language = (doc/:source).first.attributes['language']
    # There may be elements called 'title', 'abbreviation' etc
    # elsewhere (typically inside the TEI header), so we must be
    # careful to get only the children of 'source'.
    title = doc.search('source > title').inner_html
    abbreviation = doc.search('source > abbreviation').inner_html
    tracked_references = doc.search('source > tracked-references').inner_html
    reference_format = doc.search('source > reference-format').inner_html
    tei_header = (doc/:source/:"tei-header").to_s

    source = Source.find_by_code(identifier)
    raise "Source #{identifier} already exists" if source

    tracked_references = tracked_references.split(/\s*,\s*/).inject({}) do |v, e|
      sect, level = e.split(/\s*=\s*/)
      v[level] ||= []
      v[level] << sect
      v
    end

    reference_format = reference_format.split(/,(?=(?:[^\"]*\"[^\"]*\")*(?![^\"]*\"))/).map { |s| s.tr('"', '') }.inject({}) do |v, e|
      sect, fmt = e.split(/\s*=\s*/)
      v[sect.to_sym] = fmt
      v
    end

    source = Source.create!(:code => identifier,
                            :language => language,
                            :title => title,
                            :citation_part => abbreviation,
                            :tei_header => tei_header)

    # We do not need versioning for imports, so disable it.
    Sentence.disable_auditing
    Token.disable_auditing

    (doc/:div).each_with_index do |div, div_position|
      sd = source.source_divisions.create! :position => div_position,
        :title => (div/:title).inner_html,
        :abbreviated_title => (div/:abbreviation).inner_html

      unless (div/:"unsegmented-text").empty?
        (div/:"unsegmented-text").inner_html.chomp.gsub(/\s+/, ' ').gsub(/(\s*[—]?[\.\?:\!][—]?)\s+/, '\1#').split(/#/).map(&:chomp).each_with_index do |segment, segment_position|
          add_sentence(sd, segment_position, segment)
        end
      else
        (div/:sentence).each_with_index do |sentence, sentence_position|
          presentation_string = (sentence/:presentation).inner_html
          s = add_sentence(sd, sentence_position, presentation_string)

          token_id_map = {}

          # First pass to set up the token data.
          (sentence/:token).each_with_index do |token, token_position|
            t = s.tokens.create! :form => token.attributes['form'],
              :empty_token_sort => token.attributes['empty-token-sort'],
              :foreign_ids => token.attributes['foreign-ids'],
              :token_number => token_position
            t.morph_features = token.attributes['morph-features']
            t.source_morph_features = token.attributes['source-morph-features']
            # TODO: citation
            t.save!

            token_id_map[token.attributes['id']] = t
          end

          # Make another pass to set up dependencies.
          (sentence/:token).each_with_index do |token, token_position|
            t = token_id_map[token.attributes['id']]
            t.head_id = token_id_map[token.attributes['head-id']]
            t.relation = token.attributes['relation']
            t.save! if t.changed?
          end

          (sentence/:note).each do |note|
            originator = ImportSource.find_or_create_by_tag :tag => note.attributes['originator'],
              :summary => note.attributes['originator']

            s.notes.create! :contents => note.inner_html,
              :originator => originator
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
