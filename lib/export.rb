#--
#
# export.rb - Export functions for PROIEL sources
#
# Copyright 2007, 2008, 2009, 2010 University of Oslo
# Copyright 2007, 2008, 2009, 2010 Marius L. Jøhndal
# Copyright 2010 Dag Haug
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
require 'builder'
require 'metadata'

# Monkeypatch builder with a less obtuse version of XML escaping
class String
  def to_xs
    self.gsub(/'/, '&quot;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
  end
end

# Abstract source exporter.
class SourceXMLExport
  # Creates a new exporter that exports the source +source+.
  #
  # ==== Options
  # reviewed_only:: Only include reviewed sentences. Default: +false+.
  # sem_tags:: Include semantic tags. Default: +false+.
  # info:: Include information structure. Default: +false+.
  def initialize(source, options = {})
    options.assert_valid_keys(:reviewed_only, :sem_tags, :source_division, :info)
    options.reverse_merge! :reviewed_only => false

    @source = source
    @metadata = source.metadata if source.metadata.valid?
    @options = options
  end

  # Writes the exported data to a file or an IO object.
  def write(file)
    case file
    when String
      File.open(file, 'w') { |f| do_export(f) }
    else
      do_export(file)
    end
  end

  # Returns the sentences to be exported by the malt or tigerxml
  # exporter. (The PROIEL XML exporter will export the presentation of
  # all sentences.)
  def filtered_sentences
    filtered_source_divisions.map { |sd| filter_sentences(sd) }.flatten
  end

  # Returns the source_divisions to be exported
  def filtered_source_divisions
    unless @options[:source_division]
      @source.source_divisions
    else
      @options[:source_division].map { |d| SourceDivision.find(d) }.sort { |x,y| x.position <=> y.position }
    end
  end

  # Returns the sentences from a single source_division which are to
  # be exported by the exporter
  def filter_sentences(source_division)
      if @options[:reviewed_only]
        source_division.sentences.reviewed
      else
        source_division.sentences.select(&:has_dependency_annotation?)
      end
  end

  # Returns the public identifier for the source.
  def identifier
    @source.code
  end
end

# Source exporter for the PROIEL XML format.
class PROIELXMLExport < SourceXMLExport
  protected

  def do_export(file)
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    builder.source(:id => identifier, :language => @source.language.iso_code) do
      builder.title @source.title
      builder.abbreviation @source.abbreviation
      builder.tag!("tracked-references", @source.tracked_references.map { |k, v| v.map { |x| [x, k].join('=') }}.flatten.join(','))
      builder.tag!("tei-header") { @metadata.write(builder) }

      filtered_source_divisions.each do |sd|
        write_source_division(builder, sd)
      end
    end
  end

  private

  def write_source_division(builder, sd)
    builder.div do
      builder.title sd.title
      builder.abbreviation sd.abbreviated_title

      sd.sentences.each do |s|
        builder.sentence do
          builder.presentation { |x| x << s.presentation }
          write_sentence(builder, s) if (@options[:reviewed_only] and s.is_reviewed?) or (!@options[:reviewed_only] and s.has_dependency_annotation?)
        end
      end
    end
  end

  def write_sentence(builder, s)
    s.tokens.dependency_annotatable.each do |t|
      attributes = {}
      features = %w(id form empty_token_sort morph_features foreign_ids head_id relation)
      features += %w(antecedent_id info_status) if @options[:info]
      features.each do |f|
        v = t.send(f)
        attributes[f.to_s.gsub('_', '-').to_sym] = v.to_s if v
      end

      # Add semantic tags if wanted
      if @options[:sem_tags]
        sem_tags = t.semantic_tags
        sem_tags += t.lemma.semantic_tags.reject { |tag| sem_tags.map(&:semantic_attribute).include?(tag.semantic_attribute) } if t.lemma
        sem_tags.each do |st|
          attributes[st.semantic_attribute.tag] = st.semantic_attribute_value.tag
        end
      end

      unless t.slashees.empty? # this extra test avoids <token></token> style XML
        builder.token attributes do
          builder.slashes do
            t.slash_out_edges.each do |slash_out_edge|
              builder.slash :target => slash_out_edge.slashee_id, :label => slash_out_edge.relation.tag
            end
          end
        end
      else
        builder.token attributes
      end
    end

  end
end

# Source exporter for the TigerXML format
# (http://www.ims.uni-stuttgart.de/projekte/TIGER/TIGERSearch/doc/html/TigerXML.html)
# in the variant used by VISL under the name `TIGER dependency format'
# (http://beta.visl.sdu.dk/treebanks.html#TIGER_dependency_format).
class TigerXMLExport < SourceXMLExport
  MORPHOLOGY_BUNDLES = [:person_number, :tense_mood_voice, :case_number, :gender, :degree, :strength, :inflection]

  def initialize(source, options = {})
    super(source, options)

    @features = ([:lemma, :pos] + MORPHOLOGY_BUNDLES).inject([]) { |m, f| m << [f, 'FREC'] }

    if @options[:sem_tags]
      # FIXME: what if there is a conflect between features
      SemanticAttribute.all.each { |sa| @features << [sa.tag.downcase.to_sym, 'FREC'] }
    end

    if @options[:info]
      ['info_status', 'antecedent_id'].each { |f| @features << [f, 'FREC'] }
    end

    @features << [:word, 'FREC']
  end

  protected

  def do_export(file)
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    builder.corpus(:id => self.identifier) do
      builder.head { write_head(builder) }
      builder.body { write_body(builder) }
    end
  end

  private

  def write_meta(builder)
    builder.name(@source.title)
  end

  def write_head(builder)
    builder.meta { write_meta(builder) }
    builder.annotation do
      @features.each do |f|
        builder.feature(:name => f.first.to_s, :domain => f.last) #FIXME - we probably want to list possible values
      end

      builder.edgelabel do
        builder.value(:name => '--')
        Relation.primary.each do |relation|
          builder.comment! relation.summary
          builder.value(:name => relation.tag)
        end
      end

      builder.secedgelabel do
        Relation.all.each do |relation|
          builder.comment! relation.summary
          builder.value(:name => relation.tag)
        end
      end
    end
  end

  def token_attrs(s, t, type)
    attrs = @features.select { |f| f.last == 'FREC' or f.last == type }.map(&:first).inject({}) { |m, o| m[o] = nil; m }

    attrs.keys.each do |attr|
      if attr == :tiger
        attrs[attr] = t.id
      elsif [:word, :cat].include?(attr)
        if t.empty_token_sort == 'P'
          attrs[attr] = "PRO-#{t.relation.tag.upcase}"
        elsif t.form
          attrs[attr] = t.form
        end
      elsif SemanticAttribute.all.map { |sa| sa.tag.downcase.to_sym }.include?(attr)
        attrs[attr] = t.sem_tags_to_hash[attr]
      elsif attr == :lemma
        attrs[attr] = t.morph_features.lemma_s.split(",")[0] if t.morph_features
      elsif attr == :pos
        if t.empty_token_sort
          attrs[attr] = t.empty_token_sort + "-"
        else
          attrs[attr] = t.morph_features.lemma_s.split(",")[1] if t.morph_features
        end
      elsif MORPHOLOGY_BUNDLES.include?(attr)
        attrs[attr] = attr.to_s.split("_").map { |a| t.send(a.to_sym).nil? ? "-" : t.send(a.to_sym) }.join
      elsif t.respond_to?(attr)
        attrs[attr] = t.send(attr)
      else
        raise "Do not know how to get required attribute #{attr}"
      end
      attrs[attr] ||= "--"
    end
    attrs
  end

  protected

  def write_body(builder)
    filtered_sentences.each do |s|
      builder.s(:id => "s#{s.id}") do
        root_node_id = "s#{s.id}_root"

        builder.graph(:root => root_node_id) do
          builder.terminals do
            (@options[:info] ? s.tokens_with_dependents_and_info_structure.with_prodrops_in_place.reject { |t| ['C', 'V'].include?(t.empty_token_sort) } : s.tokens.morphology_annotatable).each do |t|
              builder.t(token_attrs(s, t, 'T').merge({ :id => "w#{t.id}"}))
            end
          end

          if s.has_dependency_annotation?
            builder.nonterminals do
              # Emit the empty root node
              h = @features.select { |f| ['FREC', 'NT'].include?(f.last) }.map(&:first).inject({}) { |m, o| m[o] = '--'; m }.merge({:id => root_node_id })
              builder.nt(h) do
                s.tokens.dependency_annotatable.reject(&:head).each do |t|
                  builder.edge(:idref => "p#{t.id}", :label => t.relation.tag)
                end
              end

              # Do the actual nodes including pro drops if we are
              # exporting info structure as well
              (@options[:info] ? s.tokens_with_dependents_and_info_structure.with_prodrops_in_place : s.tokens.dependency_annotatable).each do |t|
                builder.nt(token_attrs(s, t, 'NT').merge({ :id => "p#{t.id}"})) do
                  # Add an edge between this node and the correspoding terminal node unless
                  # this is not a morphtaggable node.
                  builder.edge(:idref => "w#{t.id}", :label => '--') if t.is_morphtaggable? or (@options[:info] and t.empty_token_sort == 'P')

                  # Add primary dependency edges including empty pro tokens if we are exporting info structure as well
                  (@options[:info] ? t.dependents : t.dependents.reject { |p| p.empty_token_sort == 'P' }).each { |d| builder.edge(:idref => "p#{d.id}", :label => d.relation.tag) }

                  # Add secondary dependency edges, ignoring those
                  # pointing upwards, since they are only there for
                  # validation purposes
                  SlashEdge.find_all_by_slasher_id(t.id).reject { |se| se.slashee_id == t.head_id }. each do |se|
                    builder.secedge(:idref => "p#{se.slashee_id}", :label => se.relation.tag)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

# Source exporter for the MaltXML format
# (http://w3.msi.vxu.se/~nivre/research/MaltXML.html).
# Note that this exporter does not support secondary edges.
class MaltXMLExport < SourceXMLExport
  protected

  def do_export(file)
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    builder.treebank(:id => self.identifier,
                     'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
                     'xmlns:treebank' => "http://www.msi.vxu.se/~rics/treebank",
                     'xsi:schemaLocation' => "http://www.msi.vxu.se/~rics/treebank treebank.xsd") do 
      builder.head do
        builder.annotation do
          builder.attribute(:name => "head")
          builder.attribute(:name => "deprel") do
            Relation.primary.each do |relation|
              builder.comment! relation.summary
              builder.value(:name => relation.tag)
            end
          end
          builder.attribute(:name => "form")
          builder.attribute(:name => "morphology")
          builder.attribute(:name => "lemma")
        end
      end

      builder.body do
        filtered_sentences.each do |s|
          builder.sentence(:id => s.id) do
            # Create a mapping from PROIEL token IDs to one-based, sentence
            # internal IDs. (I don't like reusing the same id attribute values in 
            # XML in this manner, but what can one do...) The ID 1 is reserved
            # for an empty root node to be added later, so we start the mapping at
            # ID 2.
            ids = s.tokens.dependency_annotatable.map(&:id)
            local_token_ids = Hash[*ids.zip((2..(ids.length + 1)).to_a).flatten]

            # Add another one to function as a root node. This is necessary
            # since MaltXML requires there to be a single `root word' with 
            # its deprel attribute set to `ROOT'. We also need to emit this
            # word in the XML file.
            local_token_ids[nil] = 1
            builder.word({ :id => 1, :head => 0, :deprel => 'ROOT' })

            s.tokens.dependency_annotatable.each do |t|
              attrs = { :id => local_token_ids[t.id]}
              attrs.merge!({ :form => t.form }) if t.form

              if s.has_dependency_annotation?
                attrs.merge!({ :head => local_token_ids[t.head_id] })
                attrs.merge!({ :deprel => t.relation.tag })
              end

              if s.has_morphological_annotation? and t.is_morphtaggable?
                attrs.merge!({ :morphology => t.morph_features.morphology_s,
                               :lemma => t.morph_features.lemma_s })
              end

              builder.word(attrs)
            end
          end
        end
      end
    end
  end
end
