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

class Tiger2Exporter < TigerXMLExporter
  only_exports :reviewed

  def initialize(source, options = {})
    super(source, options)

    @features.delete_if { |o| o.first == 'antecedent_id' }
    @ident = 'xml:id'
  end

  def self.schema_file_name
    'Tiger2.xsd'
  end

  protected

  def write_source!(builder, s)
    builder.corpus('xml:id' => s.human_readable_id,
                   'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                   'xsi:schemaLocation' => 'http://korpling.german.hu-berlin.de/tiger2/V2.0.5/ http://korpling.german.hu-berlin.de/tiger2/V2.0.5/Tiger2.xsd',
                   'xmlns:tiger2' => 'http://korpling.german.hu-berlin.de/tiger2/V2.0.5/',
                   'xmlns' => 'http://korpling.german.hu-berlin.de/tiger2/V2.0.5/') do
      builder.head do
        builder.meta do
          builder.name(s.title)
          builder.author('The PROIEL project')
          builder.date(Time.now)
          builder.description
          builder.format
          builder.history
        end

        declare_annotation(builder)
      end

      builder.body do
        yield builder
      end
    end
  end

  def declare_edgelabels(builder)
    builder.feature(:name => "label", 'type' => "prim", :domain => "edge") do
      declare_primary_edges(builder)
    end

    builder.feature(:name => "label", 'type' => "sec", :domain => "edge") do
      declare_secedges(builder)
    end

    builder.feature(:name => "label", 'type' => "coref", :domain => "edge") do
      builder.value(:name => "antecedent")
      builder.value(:name => "inference")
    end
  end

  def write_sentence!(builder, s)
    builder.s('xml:id' => "s#{s.id}") do
      builder.graph(:root => "s#{s.id}_root") do
        write_terminals(s, builder)
        write_nonterminals(s, builder) if s.has_dependency_annotation?
      end
    end
  end

  def write_root_edge(t, builder)
    builder.edge('tiger2:type' => "prim", 'tiger2:target' => "p#{t.id}", :label => t.relation.tag)
  end

  def write_edges(t, builder)
    # Add an edge between this node and the correspoding terminal node unless
    # this is not a morphtaggable node.
    builder.edge('tiger2:type' => "prim", 'tiger2:target' => "w#{t.id}", :label => '--') if t.is_morphtaggable? or t.empty_token_sort == 'P'

    # Add primary dependency edges including empty pro tokens if we are exporting info structure as well
    t.dependents.each { |d| builder.edge('tiger2:type' => "prim", 'tiger2:target' => "p#{d.id}", :label => d.relation.tag) }

    # Add secondary dependency edges
    get_slashes(t).each do |se|
      builder.edge('tiger2:type' => "sec", 'tiger2:target' => "p#{se.slashee_id}", :label => se.relation.tag)
    end

    builder.edge('tiger2:type' => "coref", 'tiger2:target' => t.antecedent_id, :label => (t.information_status_tag == 'acc_inf' ? "inference" : "antecedent") )
  end
end
