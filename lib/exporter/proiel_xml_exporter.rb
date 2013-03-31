# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
# Copyright 2010, 2011, 2012 Dag Haug
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

# Source exporter for the PROIEL XML format.
class PROIELXMLExporter < XMLSourceExporter
  def self.schema_file_name
    'proiel.xsd'
  end

  protected

  def write_toplevel!(file)
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    builder.proiel('export-time' => DateTime.now.xmlschema, 'schema-version' => "1.0") do
      builder.annotation do
        builder.relations do
          RelationTag.all.each do |value|
            builder.tag!('value', :tag => value.tag, :summary => value.summary, :primary => value.primary, :secondary => value.secondary)
          end
        end

        builder.tag! 'parts-of-speech' do
          PartOfSpeechTag.all.each do |value|
            builder.tag!('value', :tag => value.tag, :summary => value.summary)
          end
        end

        builder.morphology do
          MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.each_with_index do |field|
            values = MorphFeatures::MORPHOLOGY_SUMMARIES[field]
            builder.field :tag => field do
              values.each do |value, summary|
                builder.value :tag => value, :summary => summary
              end
            end
          end
        end

        builder.tag! 'information-statuses' do
          InformationStatusTag.all.each do |value|
            builder.tag!('value', :tag => value.tag, :summary => value.summary)
          end
        end
      end

      yield builder
    end
  end

  def write_source!(builder, s)
    builder.source(:id => s.human_readable_id, :language => s.language_tag) do
      builder.title s.title
      builder.author s.author unless s.author.blank?
      builder.edition s.edition if s.edition.blank?
      builder.tag!('citation-part', s.citation_part)
      builder.tag!('tei-header') do
        builder << s.metadata.export_form if s.metadata
      end

      yield builder
    end
  end

  def write_source_division!(builder, sd)
    attrs = pull_features(sd,
                          [],
                          %w(presentation_before presentation_after))

    builder.div(attrs) do
      builder.title sd.title

      yield builder
    end
  end

  def write_sentence!(builder, s)
    attrs = pull_features(s,
                          %w(id status),
                          %w(presentation_before presentation_after))

    builder.sentence(attrs) do
      yield builder
    end
  end

  def write_token!(builder, t)
    mandatory_features = %w(id)
    optional_features = %w(citation_part lemma part_of_speech morphology head_id relation
                           antecedent_id information_status contrast_group)

    if t.empty_token_sort.blank?
      mandatory_features << :form
      optional_features += %w(presentation_before presentation_after
                              foreign_ids)
    else
      mandatory_features << :empty_token_sort
    end

    attrs = pull_features(t, mandatory_features, optional_features)
    attrs.merge!(t.sem_tags_to_hash) if @options[:sem_tags]

    unless t.slashees.empty? and t.notes.empty? # this extra test avoids <token></token> style XML
      builder.token attrs do
        t.slash_out_edges.each do |slash_out_edge|
          builder.slash 'target-id' => slash_out_edge.slashee_id, 'relation' => slash_out_edge.relation_tag
        end

        t.notes.each do |note|
        end
      end
    else
      builder.token attrs
    end
  end

  private

  def pull_features(obj, mandatory_features, optional_features)
    attrs = {}

    mandatory_features.each do |f|
      v = obj.send(f.to_sym)

      attrs[f.to_s.gsub('_', '-')] = (v.respond_to?(:export_form) ? v.export_form : v.to_s)
    end

    optional_features.each do |f|
      v = obj.send(f.to_sym)

      if v and v.to_s != ''
        attrs[f.to_s.gsub('_', '-')] = (v.respond_to?(:export_form) ? v.export_form : v.to_s)
      end
    end

    attrs
  end
end
