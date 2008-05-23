#!/usr/bin/env ruby
#
# exporter - Export a PROIEL source to various export formats
#
# Written by Marius L. Jøhndal
#

gem 'builder', '~> 2.0'

# Abstract source exporter.
class SourceExport
  # Creates a new exporter that exports the source +source+ 
  #
  # ==== Options
  # reviewed_only:: Only include reviewed sentences. Default: +false+.
  def initialize(source, options = {})
    options.assert_valid_keys(:reviewed_only)
    options.reverse_merge! :reviewed_only => false

    @source = source
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


  # Returns the sentences to be exported by the exporter.
  def filtered_sentences
    @options[:reviewed_only] ? @source.reviewed_sentences : @source.sentences
    #FIXME
    x = @options[:reviewed_only] ? @source.reviewed_sentences : @source.sentences
    x[0, 100]
  end

  protected

  # Returns the public identifier for the source.
  def identifier
    @source.code
  end
end

# Source exporter for the PROIEL XML format.
class PROIELXMLExport < SourceExport
  protected

  def do_export(file)
    PROIEL::Writer.new(file, identifier, @source.language, 
                       @source.attributes.slice("title", "edition", "source", "editor", "url")) do |w|
      filtered_sentences.each do |sentence|
        sentence.tokens.each do |token|
          w.track_references(sentence.book.code, sentence.chapter, token.verse)

          attributes = { :id => token.id, :sort => token.sort.to_s.gsub(/_/, '-') }
          attributes[:relation] = token.relation if token.relation
          attributes[:head] = token.head_id if token.head
          attributes[:slashes] = token.slashees.collect { |s| s.id }.join(' ') unless token.slashees.empty?
          attributes[:morphtag] = token.morphtag if token.morphtag
          attributes[:lemma] = token.lemma.presentation_form if token.lemma
          attributes['composed-form'] = token.composed_form if token.composed_form

          w.emit_word(token.form, attributes)
        end
        w.next_sentence
      end
    end
  end
end

# Source exporter for the TigerXML format
# (http://www.ims.uni-stuttgart.de/projekte/TIGER/TIGERSearch/doc/html/TigerXML.html)
# in the variant used by VISL under the name `TIGER dependency format'
# (http://beta.visl.sdu.dk/treebanks.html#TIGER_dependency_format).
class TigerXMLExport < SourceExport
  protected

  def do_export(file)
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    builder.corpus(:id => self.identifier) do
      builder.meta { write_meta(builder) } 
      builder.head { write_head(builder) }
      builder.body { write_body(builder) }
    end
  end

  private

  def write_meta(builder)
    builder.name(@source.title)
  end

  def write_head(builder)
    builder.annotation do
      builder.feature(:name => 'form', :domain => 'FREC')
      builder.feature(:name => 'morphtag', :domain => 'FREC')
      builder.feature(:name => 'lemma', :domain => 'FREC')
      builder.edgelabel do
        builder.value(:name => '--')
        PROIEL::RELATIONS.each_pair do |key, value|
          builder.comment! value.description
          builder.value(:name => key)
        end
      end
      builder.secedgelabel do
        builder.value(:name => '*')
      end
    end
  end

  def token_attrs(s, t)
    attrs = { :form => t.form || '' }

    if s.has_morphological_annotation? and t.is_morphtaggable?
      attrs.merge!({ :morphtag => t.morph_lemma_tag.morphtag.to_s, 
                     :lemma => t.morph_lemma_tag.lemma.to_s })
    else
      attrs.merge!({ :morphtag => '',
                     :lemma => '' })
    end
    attrs
  end

  def write_body(builder)
    filtered_sentences.each do |s|
      builder.s(:id => "s#{s.id}") do
        root_node_id = "s#{s.id}_root"

        builder.graph(:root => root_node_id) do
          builder.terminals do
            s.morphtaggable_tokens.each do |t|
              builder.t(token_attrs(s, t).merge({ :id => "w#{t.id}"}))
            end
          end

          if s.has_dependency_annotation?
            builder.nonterminals do
              # Emit the empty root node
              builder.nt(:id => root_node_id, :form => '', :morphtag => '', :lemma => '') do
                s.root_tokens.each do |t|
                  builder.edge(:idref => "p#{t.id}", :label => t.relation)
                end
              end

              # Do the actual nodes
              s.dependency_tokens.each do |t|
                builder.nt(token_attrs(s, t).merge({ :id => "p#{t.id}"})) do
                  # Add an edge between this node and the correspoding terminal node unless
                  # this is not a morphtaggable node.
                  builder.edge(:idref => "w#{t.id}", :label => '--') if t.is_morphtaggable?

                  # Add dependency edges, primary and secondary.
                  t.dependents.each { |d| builder.edge(:idref => "p#{d.id}", :label => d.relation) }
                  t.slashers.each { |d| builder.secedge(:idref => "p#{d.id}", :label => '*') }
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
class MaltXMLExport < SourceExport
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
            PROIEL::RELATIONS.each_pair do |key, value|
              builder.comment! value.description
              builder.value(:name => key)
            end
          end
          builder.attribute(:name => "form")
          builder.attribute(:name => "morphtag")
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
            ids = s.dependency_tokens.collect(&:id)
            local_token_ids = Hash[*ids.zip((2..(ids.length + 1)).to_a).flatten]

            # Add another one to function as a root node. This is necessary
            # since MaltXML requires there to be a single `root word' with 
            # its deprel attribute set to `ROOT'. We also need to emit this
            # word in the XML file.
            local_token_ids[nil] = 1
            builder.word({ :id => 1, :head => 0, :deprel => 'ROOT' })

            s.dependency_tokens.each do |t|
              attrs = { :id => local_token_ids[t.id]}
              attrs.merge!({ :form => t.form }) if t.form

              if s.has_dependency_annotation?
                attrs.merge!({ :head => local_token_ids[t.head_id] })
                attrs.merge!({ :deprel => t.relation })
              end

              if s.has_morphological_annotation? and t.is_morphtaggable?
                attrs.merge!({ :morphtag => t.morph_lemma_tag.morphtag.to_s, 
                               :lemma => t.morph_lemma_tag.lemma.to_s })
              end

              builder.word(attrs)
            end
          end
        end
      end
    end
  end
end

if $0 == __FILE__
  require '../config/environment'

  s = Source.find(1)
#  e = MaltXMLExport.new(s)
#  e.write(File.new('maltxml.xml', 'w'))
  e = TigerXMLExport.new(s, :reviewed_only => true)
  e.write(STDOUT) #File.new('maltxml.xml', 'w'))
end
