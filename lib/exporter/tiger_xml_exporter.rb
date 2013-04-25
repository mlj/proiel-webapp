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

# Source exporter for the TigerXML format
# (http://www.ims.uni-stuttgart.de/projekte/TIGER/TIGERSearch/doc/html/TigerXML.html)
# in the variant used by VISL under the name 'TIGER dependency format'
# (http://beta.visl.sdu.dk/treebanks.html#TIGER_dependency_format).
class TigerXMLExporter < XMLSourceExporter
  only_exports :reviewed

  def initialize(source, options = {})
    super(source, options)
    @ident = 'id'

    @morphological_features = [:person_number, :tense_mood_voice, :case_number, :gender, :degree, :strength, :inflection]
    @semantic_features = SemanticAttribute.all.map(&:tag).map(&:downcase).map(&:to_sym)
    @other_features = [:lemma, :pos, :information_status, :antecedent_id, :word]

    # FIXME: what if there is a conflict between features
    selected_features = @morphological_features + @other_features
    selected_features += @semantic_features if @options[:sem_tags]

    @features = selected_features.map { |f| [f, 'FREC'] }
  end

  def self.schema_file_name
    'TigerXML.xsd'
  end

  protected

  def write_toplevel!(file)
    builder = Builder::XmlMarkup.new(:target => file, :indent => 2)
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    yield builder
  end

  def write_source!(builder, s, &block)
    builder.corpus(:id => s.human_readable_id) do
      builder.head do
        builder.meta do
          builder.name(s.title)
        end

        declare_annotation(builder)
      end

      builder.body do
        yield builder
      end
    end
  end

  def declare_annotation(builder)
    builder.annotation do
      @features.each do |f|
        builder.feature(:name => f.first.to_s, :domain => f.last) #FIXME - we probably want to list possible values
      end
      declare_edgelabels(builder)
    end
  end

  def declare_primary_edges(builder)
    builder.value(:name => '--')
    RelationTag.all.select(&:primary).each do |relation|
      builder.value({:name => relation.tag}, relation.summary)
    end
  end

  def declare_secedges(builder)
    RelationTag.all.select(&:secondary).each do |relation|
      builder.value({:name => relation.tag}, relation.summary)
    end
  end

  def declare_edgelabels(builder)
    builder.edgelabel { declare_primary_edges(builder) }
    builder.secedgelabel { declare_secedges(builder) }
  end

  def token_attrs(s, t, type)
    attrs = @features.select { |f| f.last == 'FREC' or f.last == type }.map(&:first).inject({}) { |m, o| m[o] = nil; m }

    attrs.keys.each do |attr|
      case attr
      when :word, :cat
        case t.empty_token_sort
        when 'P'
          attrs[attr] = "PRO-#{t.relation.tag.upcase}"
        when NilClass
          attrs[attr] = t.form
        end
      when *@semantic_features
        attrs[attr] = t.sem_tags_to_hash[attr]
      when :lemma
        attrs[attr] = t.morph_features.lemma_s.split(",")[0] if t.morph_features
      when :pos
        if t.empty_token_sort
          attrs[attr] = t.empty_token_sort + "-"
        else
          attrs[attr] = t.morph_features.lemma_s.split(",")[1] if t.morph_features
        end
      when *@morphological_features
        attrs[attr] = attr.to_s.split("_").map { |a| t.send(a.to_sym).nil? ? "-" : t.send(a.to_sym) }.join
      else
        if t.respond_to?(attr)
          attrs[attr] = t.send(attr)
        else
          raise "Do not know how to get required attribute #{attr}"
        end
      end
      attrs[attr] ||= "--" unless @options[:ignore_nils]
    end
    attrs.delete_if { |k, v| v.nil? }
  end

  protected

  def write_terminals(s, builder)
    builder.terminals do
      s.tokens_with_dependents_and_info_structure.with_prodrops_in_place.reject { |t| ['C', 'V'].include?(t.empty_token_sort) }.each do |t|
        builder.t(token_attrs(s, t, 'T').merge({ @ident => "w#{t.id}"}))
      end
    end
  end

  def write_edges(t, builder)
    # Add an edge between this node and the correspoding terminal node unless
    # this is not a morphtaggable node.
    builder.edge(:idref => "w#{t.id}", :label => '--') if t.is_morphtaggable? or t.empty_token_sort == 'P'

    # Add primary dependency edges including empty pro tokens if we are exporting info structure as well
    t.dependents.each { |d| builder.edge(:idref => "p#{d.id}", :label => d.relation.tag) }

    # Add secondary dependency edges
    get_slashes(t).each do |se|
      builder.secedge(:idref => "p#{se.slashee_id}", :label => se.relation.tag)
    end
  end

  def get_slashes(t)
    SlashEdge.find_all_by_slasher_id(t.id).reject do |se|
      case @options[:cycles]
      when 'all'
        se.cyclic?
      when 'heads'
        se.points_to_head?
      else
        false
      end
    end
  end

  def write_root_edge(t, builder)
    builder.edge(:idref => "p#{t.id}", :label => t.relation.tag)
  end

  def write_nonterminals(s, builder)
    builder.nonterminals do
      # Emit the empty root node
      h = @features.select { |f| ['FREC', 'NT'].include?(f.last) }.map(&:first).inject({}) { |m, o| m[o] = '--'; m }.merge({@ident => "s#{s.id}_root" })
      builder.nt(h) do
        s.tokens.takes_syntax.reject(&:head).each do |t|
          write_root_edge(t, builder)
        end
      end

      # Do the actual nodes including pro drops if we are
      # exporting info structure as well
      s.tokens_with_dependents_and_info_structure.with_prodrops_in_place.each do |t|
        builder.nt(token_attrs(s, t, 'NT').merge({ @ident => "p#{t.id}"})) do
          write_edges(t, builder)
        end
      end
    end
  end

  def write_sentence!(builder, s)
    builder.s(:id => "s#{s.id}") do
      builder.graph(:root => "s#{s.id}_root") do
        write_terminals(s, builder)
        write_nonterminals(s, builder) if s.has_dependency_annotation?
      end
    end
  end
end

