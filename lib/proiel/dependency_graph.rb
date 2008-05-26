#!/usr/bin/env ruby
#
# dependency_graph.rb - Dependency graph manipulation and validation
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: $
#
require 'extensions'
require 'enumerator'
require 'open3'
require 'proiel/morphtag'

module Lingua
  class DependencyGraphNode
    attr_reader :relation
    attr_reader :head
    attr_reader :identifier
    attr_accessor :data

    def initialize(identifier, relation, head, data = {})
      @identifier = identifier
      @relation = relation ? relation.to_sym : nil
      @data = data
      @head = head
      @dependents = {}
    end

    def add_dependent(node)
      @dependents[node.identifier] = node
    end

    # Returns the dependents of the node.
    def dependents
      @dependents.values
    end

    # Returns +true+ if the node has any dependents. If +relation+
    # is given, then returns +true+ only if the node has any
    # dependents related to the node by +relation+.
    def has_dependents?(relation = nil)
      relation ? dependents.any? { |t| t.relation == relation } : !dependents.empty?
    end

    # Returns all the dependents of the node that have a particular
    # relation +relation+.
    def dependents_by_relation(*relations)
      dependents.select { |n| relations.include?(n.relation) } 
    end

    # Returns the siblings of the node.
    def siblings
      head ? head.dependents.reject { |t| t == self } : []
    end

    # Returns +true+ if the node has any siblings. If +relation+ is
    # given, then returns +true+ only if the node has any siblings
    # related to their head by +relation+.
    def has_siblings?(relation = nil)
      relation ? siblings.any? { |t| t.relation == relation } : !siblings.empty?
    end

    def is_root?
      @identifier == :root
    end

    # Returns the `depth' of the node, i.e. the distance from the root in number of edges,
    # or, if conceptualised as a tree, the depth of the node relative to the rood node.
    def depth
      @identifier == :root ? 0 : head.depth + 1
    end

    # Returns the maximum `depth' of the subgraph constituted by this node and its dependents.
    def max_depth
      dependents.empty? ? depth : dependents.collect(&:max_depth).max
    end

    def inspect_subgraph(indentation = 0)
      unless dependents.empty?
        s = ' ' * indentation + "[#{identifier}: #{relation.inspect}, #{data.inspect}] -> {\n"
        dependents.each { |d| s += d.inspect_subgraph(indentation + 2) }
        s += ' ' * indentation + "}\n" 
        s
      else
        ' ' * indentation + "[#{identifier}: #{relation.inspect}, #{data.inspect}]\n"
      end
    end

    def each_dependent(&block)
      raise ArgumentError, "Block expected" unless block_given?

      dependents.each do |d|
        block.call(d)
        d.each_dependent(&block)
      end
    end
  end

  class SlashedDependencyGraphNode < DependencyGraphNode
    attr_reader :slashes

    def initialize(identifier, relation, head, data = {})
      super
      @slashes = []
    end

    def add_slash(slash)
      @slashes << slash
    end

    def has_slash?
      !@slashes.empty?
    end

    alias :has_slashes? :has_slash?
  end

  class DependencyGraph
    attr_reader :root

    def initialize(options = {})
      @node_class ||= DependencyGraphNode
      @nodes = {} 
      @root = @node_class.new(:root, nil, nil)

      if block_given?
        @postponed_nodes = {}

        yield self

        # Traverse the stored postponed nodes and add them
        add_postponed_subgraph

        # Add in the slashes if we are about to end the recursion
        @postponed_nodes.each_pair do |identifier, values|
          next unless values[:slash_ids]
          values[:slash_ids].each { |slash_id| @nodes[identifier].add_slash(@nodes[slash_id]) }
        end

        @postponed_nodes = nil
      end
    end

    protected

    def add_postponed_subgraph(identifier = :root, head_identifier = nil)
      node = @postponed_nodes[identifier]
      add_node(identifier, node[:relation], head_identifier, node[:data]) unless identifier == :root
      node[:dependent_ids].each { |dependent_id| add_postponed_subgraph(dependent_id, identifier) }
    end

    public
    
    def [](identifier)
      @nodes[identifier]
    end

    # Returns the maximum `depth' of the graph.
    def max_depth
      @root.max_depth
    end

    def empty?
      @nodes.empty?
    end

    def each(&block)
      @root.each_dependent(&block)
    end

    def select(&block)
      r = []
      self.each do |n| 
        r << n if block.call(n)
      end
      r
    end

    def nodes
      r = []
      self.each { |n| r << n }
      r
    end

    #FIXME: merge with add_node and use method aliasing
    def badd_node(identifier, relation, head_identifier = nil, data = {})
      # Merge data about this token into the result structure
      @postponed_nodes[identifier] ||= { :dependent_ids => [] }
      @postponed_nodes[identifier].merge!({ :relation => relation, :data => data })
 
      # Attach this token to its head's list of dependents
      head_identifier ||= :root
      @postponed_nodes[head_identifier] ||= { :dependent_ids => [] }
      @postponed_nodes[head_identifier][:dependent_ids] << identifier

      @postponed_nodes[identifier]
    end

    def add_node(identifier, relation, head_identifier = nil, data = {})
      if @nodes[identifier]
        raise "Node with ID #{identifier} already exists"
      else
        if head_identifier and head_identifier != :root
          raise "Head node with ID #{head_identifier} does not exist" unless @nodes[head_identifier]
          @nodes[identifier] = @node_class.new(identifier, relation, @nodes[head_identifier], data)
          @nodes[head_identifier].add_dependent(@nodes[identifier])
        else
          @nodes[identifier] = @node_class.new(identifier, relation, @root, data)
          @root.add_dependent(@nodes[identifier])
        end
      end
      @nodes[identifier]
    end

    def valid?
      # FIXME: check for cycles
      true 
    end

    def inspect
      root.inspect_subgraph
    end
  end

  # FIXME: Move to PROIEL?
  module Graphviz
    FONTNAME = "Legendum"
    #FONTNAME = "RomanCyrillic Std"

    GRAPHVIZ_NODES = { 
      :fontname => FONTNAME,
      :fontsize => 12,
    }
    GRAPHVIZ_EDGES = { 
      :color => "orange", 
      :fontname => FONTNAME,
      :fontsize => 12,
      :weight => 1.0 
    }
    GRAPHVIZ_SLASHES = { 
      :color => "blue", 
      :fontcolor => "blue", 
      :fontname => FONTNAME, 
      :fontsize => 10,
      :weight => 0.0, 
      :style=> "dashed",
    }

    # Produces an image visualising the dependency graph.
    def visualise(format = :png, options = {})
      raise ArgumentError, "Invalid format #{format}" unless format == :png || format == :svg 
      Open3.popen3("dot -T#{format}") do |dot, img, err|
        if options[:linearised]
          self.linearisation_dot(dot)
        else
          self.regular_dot(dot)
        end

        @image = img.read
      end
      @image
    end

    alias :visualize :visualise

    protected

    def regular_dot(dot)
      @f = dot
      @f.puts "digraph G {"
      @f.puts "  charset=\"UTF-8\";"

      make_node(:root, GRAPHVIZ_NODES.merge({ :label => '', :shape => 'circle' }))

      @nodes.values.each do |node|
        identifier, relation, head, slashes = node.identifier, node.relation, node.head, node.slashes
        form, empty = node.data.values_at(:form, :empty)

        if node.is_empty?
          label, shape, colour = case node.interpret_empty_node
                  when :root
                    ['',  'circle', 'black']
                  when :conjunction
                    ['C', 'diamond', 'black']
                  when :verbal
                    ['V', 'circle', 'black']
                  else
                    ['?', 'box', 'red']
                  end
          make_node(identifier, GRAPHVIZ_NODES.merge({ :label => label, :shape => shape,
                                                       :fontcolor => colour }))
        else
          if node.is_coordinator? and node.has_dependents?
            make_node(identifier, GRAPHVIZ_NODES.merge({ :label => form, :shape => 'diamond' }))
          else
            make_node(identifier, GRAPHVIZ_NODES.merge({ :label => form, :shape => 'box' }))
          end
        end

        rel_colour = 'black'
        if head and relation
          make_edge(head.identifier, identifier, 
                    GRAPHVIZ_EDGES.merge({ :label => relation.to_s.upcase, :fontcolor => rel_colour }))
        end

        slashes.each do |slashee|
          make_edge(identifier, slashee.identifier, 
                    GRAPHVIZ_SLASHES.merge({ :label => node.interpret_slash(slashee).humanise.capitalize }))
        end
      end

      @f.puts "}"
      @f.close
    end

    def linearisation_dot(dot)
      @f = dot
      @f.puts "digraph G {"
      @f.puts "  charset=\"UTF-8\"; rankdir=TD; ranksep=.0005; nodesep=.05;"

      @f.puts "node [shape=none]; {"
      x = (0..self.max_depth).to_a
      @f.puts x.collect { |d| "depth#{d}" }.join(' -> ')
      @f.puts "-> WORDS [style=invis]; }"
      @f.puts "node [shape=point]; { rank = same; depth0 [label=\"\"]; root; }"

      nodes_by_depth = @nodes.values.classify(&:depth)
      nodes_by_depth.sort.each do |depth, nodes|
        @f.puts "node [shape=point]; { rank = same; "
        make_node("depth#{depth}", { :label => '' })
        nodes.each do |node|
          make_node("#{node.identifier}", { })
        end
        @f.puts "}"
      end

      @f.puts "node [shape=none]; { rank = same; WORDS [label=\"\"]; "
      @nodes.values.reject { |n| n.is_empty? }.sort_by { |n| n.token_number }.each do |node|
        make_node("f#{node.identifier}", { :label => node.data[:form] })
      end
      @f.puts "}"

      @nodes.values.each do |node|
        identifier, relation, head, slashes = node.identifier, node.relation, node.head, node.slashes
        form, empty = node.data.values_at(:form, :empty)

        if head and relation
          make_edge(head.identifier, identifier, 
                    { :label => relation.to_s.upcase, :fontcolor => 'black', :fontsize => 10 })
        end

        # Hook up the word forms with their nodes
        make_edge("f#{node.identifier}", node.identifier, { :arrowhead => 'none', :color => 'lightgrey' }) unless node.is_empty?

        slashes.each do |slashee|
          make_edge(identifier, slashee.identifier, 
                    { :weight => 0.0, :color => 'blue', :style => 'dotted', :label => node.interpret_slash(slashee) })
        end
      end

      @nodes.values.reject { |n| n.is_empty? }.sort_by { |n| n.token_number }.each_cons(2) do |n1, n2|
        make_edge("f#{n1.identifier}", "f#{n2.identifier}", { :weight => 10.0, :style => 'invis' })
      end

      @f.puts "}"
      @f.close
    end

    def make_node(obj, attrs)
      @f.puts "  #{obj} [#{join_attributes(attrs)}];"
    end

    def make_edge(obj1, obj2, attrs)
      @f.puts "  #{obj1} -> #{obj2} [#{join_attributes(attrs)}];"
    end

    def join_attributes(attrs)
      attrs.collect { |attr, value| "#{attr}=\"#{value}\"" }.join(',')
    end
  end

  class SlashedDependencyGraph < DependencyGraph
    include Graphviz

    def initialize
      @node_class ||= SlashedDependencyGraphNode
      super
    end

    def badd_node(identifier, relation, head_identifier = nil, slash_ids = [], data = {})
      returning super(identifier, relation, head_identifier, data) do |n|
        n[:slash_ids] = slash_ids
      end
    end

    def add_node(identifier, relation, head_identifier = nil, slash_ids = [], data = {})
      super(identifier, relation, head_identifier, data)
      slash_ids.each do |i| 
        raise "Slash node with ID #{i} does not exist" unless @nodes[i]
        @nodes[identifier].add_slash(@nodes[i])
      end
      @nodes[identifier]
    end

    protected

    #FIXME: inherit
    def add_postponed_subgraph(identifier = :root, head_identifier = nil)
      node = @postponed_nodes[identifier]
      add_node(identifier, node[:relation], head_identifier, [], node[:data]) unless identifier == :root 
      node[:dependent_ids].each { |dependent_id| add_postponed_subgraph(dependent_id, identifier) }
    end
  end

end

module PROIEL
  class ValidatingDependencyGraphNode < Lingua::SlashedDependencyGraphNode
    def is_empty?
      @data[:empty] or identifier == :root
    end

    def token_number 
      @data[:token_number]
    end

    def pos
      @data[:morphtag] ? @data[:morphtag].pos_to_s : nil
    end

    # Returns +true+ if this node dominates another node +x+, 
    # including if +x+ is identical to this node.
    def dominates?(x)
      if x == self
        true
      elsif x.head.nil?
        false
      else
        dominates?(x.head)
      end
    end

    # Returns +true+ if this node is a coordination node or
    # a potential coordination node, i.e. a conjunction or an 
    # empty node (which might be an asyndetic conjunction).
    def is_coordinator?
      pos == 'C-' or is_empty?
    end

    # Returns +true+ if this node is a verbal node or a potential
    # verbal node, i.e. a verb, an empty node or something with
    # the relation PRED.
    def is_verbal?
      pos == 'V-' or is_empty? or relation == :pred
    end

    # Returns +true+ if this node represents an `open' relation, i.e.
    # an XADV, XOBJ or PIV.
    def is_open?
      relation == :xadv or relation == :xobj or relation == :piv
    end

    # Returns +true+ if this node is coordinated, i.e. it descends
    # from a coordinator and this coordinator has the same relation
    # to its parent as this token has to the coordinator.
    def is_coordinated?
      head and head.is_coordinator? and relation == head.relation
    end

    # Returns +true+ if this node is a daughter of the root node.
    def is_daughter_of_root?
      head and head.is_root?
    end

    # Returns the slashes for the node, either on the node itself
    # or inherited from coordinations.
    def all_slashes
      if slashes.empty? and head and head.is_coordinator?
        head.all_slashes
      else
        slashes
      end
    end

    # Returns the minimum token number for this node and its dependent.
    # Empty nodes are ignored since these do not have any linearisation.
    def min_token_number
      c = dependents.collect(&:min_token_number).compact
      c << self.token_number unless self.is_empty?
      c.empty? ? nil : c.min
    end

    # Returns the maximum token number for this node and its dependents.
    # Empty nodes are ignored since these do not have any linearisation.
    def max_token_number
      c = dependents.collect(&:max_token_number).compact
      c << self.token_number unless self.is_empty?
      c.empty? ? nil : c.max
    end

    # Returns +true+ if this node and its dependents linearly precede 
    # another node +x+ and its dependents.
    # Empty nodes are ignored since these do not have any linearisation.
    def linearly_precedes?(x)
      a, b = self.max_token_number, x.min_token_number
      a < b or a.nil? or b.nil?
    end

    # Returns all nodes in this subgraph.
    def subgraph
      self.dependents.collect(&:subgraph).flatten << self
    end

    # Returns +true+ if all slashes from this node and its dependents
    # point to any of the same set of nodes.
    def all_slashes_contained?
      self.subgraph.collect(&:slashes).flatten.uniq.reject { |s| self.dominates?(s) }.empty?
    end

    # Returns an interpretation of a slash -- existing or potential --
    # from the node to another node +slashee+.
    def interpret_slash(slashee)
      if [:xadv, :piv, :xobj].include?(self.relation)
        :subject
      elsif self.is_empty? and self.is_verbal? and slashee.is_verbal?
        :predicate_identity
      else
        :shared_argument
      end
    end

    # FIXME
    def interpret_sentence_status
    end

    # FIXME
    def has_predicate_identity_slash?
      false
    end

    # Returns an interpretation of an empty node.
    def interpret_empty_node
      raise "Not an empty node" unless is_empty?

      if identifier == :root
        # This is the root node, which obviously has a special
        # interpretation.
        :root
      elsif dependents.all? { |d| d.relation == self.relation }
        # All dependents have the same relation to this node, as this
        # node has to its head. This indicates an asyndetic conjunction.
        :conjunction
      elsif self.has_dependents?(:sub) or self.relation == :pred or self.has_dependents?(:comp)
        # We weren't a conjunction, but have a subject or comp depdenednt,
        # or a pred relation, and that means we're verbal.
        :verbal
      else
        :unknown # FIXME: catch in validation? or log as warning
      end
    end

    # Returns a `relinearisation' of the subgraph constituted by this node and its dependents.
    def relinearise
      n = [self] + dependents
      n.sort_by { |t| t.token_number || -1 }.collect { |t| t == self ? self : t.relinearise }.flatten
    end

  end

  class ValidatingDependencyGraph < Lingua::SlashedDependencyGraph
    def initialize
      @node_class = ValidatingDependencyGraphNode 
      super
    end

    def relinearise
      @root.relinearise
    end

    def valid?(msg_handler = lambda { |token_ids, msg| })
      #FIXME
      @valid = true 
      @msg_handler = msg_handler

      test_token('Must have or inherit one outgoing slash edge', :is_open?) do |t|
        t.all_slashes.length == 1
      end

      # Root daughters may be 
      #   i. A single PRED or a single coordination of PREDs,
      #   ii. A single VOC or a single coordination of VOCs,
      #   iii. Multiple PARPREDs or coordinations of PARPREDs
      #   iv. Multiple VOCs, PREDs or coordinations of such, but only if 
      #       for each VOC or PRED subgraph
      #       a. the subgraph does not overlap with any other subgraph, and
      #       b. any slashes target only nodes in the subgraph. 
      test_token('May not be a daughter of the root node', :is_daughter_of_root?) do |t|
        [:pred, :parpred, :voc].include?(t.relation)
      end

      test_tokens('Subgraphs overlap', 
                  lambda { |t| t.is_daughter_of_root? and t.relation == :pred }) do |ts|
        # We order the PRED nodes by the maximum token number in their subgraph, then
        # look for any overlap. We cannot simply order them by their own token numbers, as they may,
        # as always, be empty nodes, and their token numbers are meaningless to us.
        x = ts.sort_by(&:max_token_number).enum_cons(2).reject { |x, y| x.linearly_precedes?(y) }
        x.flatten # Report both part-takers as in violation of constraint
      end

      test_token('Slashes are not contained by subgraph', 
                 lambda { |t| t.is_daughter_of_root? and [:pred, :voc].include?(t.relation) }) do |t|
        t.all_slashes_contained?
      end

      test_token_by_relation('The head of a PARPRED relation must be the root node or a valid coordination', :parpred) do |t|
        t.is_daughter_of_root? or t.is_coordinated?
      end

      test_token_by_relation('The head of a VOC relation must be the root node or a valid coordination', :voc) do |t|
        t.is_daughter_of_root? or t.is_coordinated?
      end

      test_token('The head of an XOBJ, XADV or PIV relation must be a verbal node or a valid coordination',
                 :is_open?) do |t| 
        # If we have a verbal head, we're alright. If not, see if we're coordinated, in which
        # case our head will have the same relation to its head as us, and will thus
        # be tested for validity on its own.
        (t.head and t.head.is_verbal?) or t.is_coordinated?
      end

      # Slashes on X* and PIV must target its head or a node dominated by the head.
      test_token("Slash must target the node's head or a node dominated by the head", 
                 :is_open?) do |t|
        not t.has_slashes? or (t.head and t.head.dominates?(t.slashes.first))
      end

      test_token_by_relation("The head of a PRED relation must be the root node, a subjunction or a valid coordination", 
                    :pred) do |t| 
        t.is_daughter_of_root? or t.head.pos == 'G-' or t.is_coordinated?
      end

      test_token("A subjunction may only be the dependent in a COMP, ADV or APOS relation", 
                 lambda { |t| t.pos == 'G-' }) do |t|
        t.relation == :comp or t.relation == :adv or t.relation == :apos
      end

      test_token("An infinitive may not be the dependent in an ADV relation", 
                 lambda { |t| t.data[:morphtag][:mood] == :n }) do |t|
        t.relation != :adv
      end

      # Morphology based head-dependent constraints

      #FIXME: special handling of non-part. vs. part.
      #FIXME: empty nodes can be verbs, but have to be excluded for now
      test_head_dependent('V----p', :adv, :ag, :apos, :arg, :aux, :comp, :nonsub, :obj, :obl, 
                          :per, :piv, :sub, :xadv, :xobj, :atr) # participles
      test_head_dependent('V', :adv, :ag, :apos, :arg, :aux, :comp, :nonsub, :obj, :obl, 
                          :per, :piv, :sub, :xadv, :xobj, :atr) # other verbs FIXME: no ATR
      test_head_dependent('N', :adnom, :apos, :atr, :aux, :comp, :narg, :part, :rel)
      test_head_dependent('A', :adv, :apos, :atr, :aux, :comp, :obl, :part)
      test_head_dependent('P', :apos, :atr, :aux, :part, :rel)

      #FIXME
      @valid
    end

    private

    # Verifies that all tokens that match the morphtag mask only have dependents related
    # to it by one of the given relations.
    def test_head_dependent(morphtag_mask, *dependent_relations)
      test_token("may only be the head in a #{dependent_relations.to_sentence(:connector => "or", :skip_last_comma => true)} relation", 
                 lambda { |t| !t.is_empty? and !t.data[:morphtag].contradicts?(MorphTag.new(morphtag_mask)) }) do |t|
        t.dependents.all? { |t| dependent_relations.include?(t.relation) }
      end
    end

    def test_tokens(msg, precond)
      candidates = @nodes.values.select { |t| precond.is_a?(Proc) ? precond.call(t) : t.send(precond) }
      failures = yield candidates

      unless failures.empty?
        #FIXME
        @valid = false
        @msg_handler.call(failures.uniq.collect(&:identifier), msg)
      end
    end

    def test_token(msg, precond)
      test_tokens(msg, precond) { |ts| ts.reject { |t| yield t }}
    end

    def test_token_by_relation(msg, *relations, &block)
      test_token(msg, lambda { |t| relations.include?(t.relation) }, &block)
    end

  end
end

if $0 == __FILE__
  require 'test/unit'
  include PROIEL

  class DependencyGraphTestCase < Test::Unit::TestCase
    def test_each_node
      g = Lingua::DependencyGraph.new
      g.add_node(1, :foo, nil)
      g.add_node(11, :bar, 1)
      g.add_node(111, :bar, 11)
      g.add_node(12, :bar, 1)
      g.add_node(121, :bax, 12)
      g.add_node(122, :bay, 12)
      g.add_node(123, :baz, 12)
      assert_equal [g[1], g[11], g[111], g[12], g[121], g[122], g[123]], g.nodes
    end

    def test_select
      g = Lingua::DependencyGraph.new
      g.add_node(1, :foo, nil)
      g.add_node(11, :bar, 1)
      g.add_node(111, :bar, 11)
      g.add_node(12, :bar, 1)
      g.add_node(121, :bax, 12)
      g.add_node(122, :bay, 12)
      g.add_node(123, :baz, 12)
      assert_equal [g[11], g[111], g[12]], g.select { |n| n.relation == :bar }
    end

    def test_siblings
      g = Lingua::DependencyGraph.new
      g.add_node(1, :foo, nil)
      g.add_node(11, :bar, 1)
      g.add_node(111, :bar, 11)
      g.add_node(12, :bar, 1)
      g.add_node(121, :bax, 12)
      g.add_node(122, :bay, 12)
      g.add_node(123, :baz, 12)

      assert_equal [], g[1].siblings
      assert_equal [g[12]], g[11].siblings
      assert_equal [], g[111].siblings
      assert_equal [g[11]], g[12].siblings
      assert_equal [g[122], g[123]], g[121].siblings

      assert_equal false, g[1].has_siblings?
      assert_equal true, g[11].has_siblings?
      assert_equal false, g[111].has_siblings?
      assert_equal true, g[12].has_siblings?
      assert_equal true, g[121].has_siblings?

      assert_equal true, g[121].has_siblings?(:bay)
      assert_equal true, g[121].has_siblings?(:baz)
      assert_equal false, g[121].has_siblings?(:bax)
    end
  end

  class ValidatingDependencyGraphTestCase < Test::Unit::TestCase
    EMITTER = lambda { |t, m| STDERR.puts "Validation error for node #{t.join(',')}: #{m}" }

    def setup_ok_graph
      g = ValidatingDependencyGraph.new
      g.add_node(250414, "pred", nil, [], {:empty=>false, :token_number => 17, :morphtag => MorphTag.new('V') })
      g.add_node(250398, "adv", 250414, [], {:empty=>false, :token_number => 1, :morphtag => MorphTag.new('V')})
      g.add_node(250399, "aux", 250414, [], {:empty=>false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(250400, "adv", 250398, [], {:empty=>false, :token_number => 3, :morphtag => MorphTag.new('V')})
      g.add_node(250401, "aux", 250400, [], {:empty=>false, :token_number => 4, :morphtag => MorphTag.new('')})
      g.add_node(250402, "sub", 250400, [], {:empty=>false, :token_number => 5, :morphtag => MorphTag.new('')})
      g.add_node(250403, "adv", 250400, [], {:empty=>false, :token_number => 6, :morphtag => MorphTag.new('V')})
      g.add_node(250404, "obl", 250403, [], {:empty=>false, :token_number => 7, :morphtag => MorphTag.new('')})
      g.add_node(250405, "atr", 250404, [], {:empty=>false, :token_number => 8, :morphtag => MorphTag.new('')})
      g.add_node(250406, "adv", 250414, [], {:empty=>false, :token_number => 9, :morphtag => MorphTag.new('V')})
      g.add_node(250407, "obl", 250406, [], {:empty=>false, :token_number => 10, :morphtag => MorphTag.new('')})
      g.add_node(250408, "atr", 250407, [], {:empty=>false, :token_number => 11, :morphtag => MorphTag.new('')})
      g.add_node(250409, "apos", 250408, [], {:empty=>false, :token_number => 12, :morphtag => MorphTag.new('')})
      g.add_node(250410, "aux", 250414, [], {:empty=>false, :token_number => 13, :morphtag => MorphTag.new('')})
      g.add_node(250411, "sub", 250414, [], {:empty=>false, :token_number => 14, :morphtag => MorphTag.new('')})
      g.add_node(250412, "obl", 250414, [], {:empty=>false, :token_number => 15, :morphtag => MorphTag.new('V')})
      g.add_node(250413, "obl", 250412, [], {:empty=>false, :token_number => 16, :morphtag => MorphTag.new('V')})
      g.add_node(250415, "obl", 250414, [], {:empty=>false, :token_number => 18, :morphtag => MorphTag.new('')})
      g.add_node(250416, "xadv", 250414, [250411], {:empty=>false, :token_number => 19, :morphtag => MorphTag.new('')})
      g
    end

    def test_graph_loading
      setup_ok_graph
    end

    def test_is_daughter_of_root
      g = setup_ok_graph
      assert_equal true, g[250414].is_daughter_of_root?
      assert_equal false,  g[250399].is_daughter_of_root?
    end

    def test_batch_setup
      k = ValidatingDependencyGraph.new do |g|
        # These are out of sequence and should be refused outside
        # the block. 
        g.badd_node(250398, "adv", 250414, [], {:empty=>false, :token_number => 1, :morphtag => MorphTag.new('V')})
        g.badd_node(250399, "aux", 250414, [], {:empty=>false, :token_number => 2, :morphtag => MorphTag.new('')})
        g.badd_node(250400, "adv", 250398, [], {:empty=>false, :token_number => 3, :morphtag => MorphTag.new('V')})
        g.badd_node(250401, "aux", 250400, [], {:empty=>false, :token_number => 4, :morphtag => MorphTag.new('')})
        g.badd_node(250402, "sub", 250400, [], {:empty=>false, :token_number => 5, :morphtag => MorphTag.new('')})
        g.badd_node(250403, "adv", 250400, [], {:empty=>false, :token_number => 6, :morphtag => MorphTag.new('V')})
        g.badd_node(250404, "obl", 250403, [], {:empty=>false, :token_number => 7, :morphtag => MorphTag.new('')})
        g.badd_node(250405, "atr", 250404, [], {:empty=>false, :token_number => 8, :morphtag => MorphTag.new('')})
        g.badd_node(250406, "adv", 250414, [], {:empty=>false, :token_number => 9, :morphtag => MorphTag.new('V')})
        g.badd_node(250407, "obl", 250406, [], {:empty=>false, :token_number => 10, :morphtag => MorphTag.new('')})
        g.badd_node(250408, "atr", 250407, [], {:empty=>false, :token_number => 11, :morphtag => MorphTag.new('')})
        g.badd_node(250409, "apos", 250408, [], {:empty=>false, :token_number => 12, :morphtag => MorphTag.new('')})
        g.badd_node(250410, "aux", 250414, [], {:empty=>false, :token_number => 13, :morphtag => MorphTag.new('')})
        g.badd_node(250411, "sub", 250414, [], {:empty=>false, :token_number => 14, :morphtag => MorphTag.new('')})
        g.badd_node(250412, "obl", 250414, [], {:empty=>false, :token_number => 15, :morphtag => MorphTag.new('V')})
        g.badd_node(250413, "obl", 250412, [], {:empty=>false, :token_number => 16, :morphtag => MorphTag.new('V')})
        g.badd_node(250414, "pred", nil, [], {:empty=>false, :token_number => 17, :morphtag => MorphTag.new('V')})
        g.badd_node(250415, "obl", 250414, [], {:empty=>false, :token_number => 18, :morphtag => MorphTag.new('')})
        g.badd_node(250416, "xadv", 250414, [250411], {:empty=>false, :token_number => 19, :morphtag => MorphTag.new('')})
      end
      l = setup_ok_graph
      assert_equal l.inspect, k.inspect
    end

    def test_slash_storage
      g = ValidatingDependencyGraph.new
      g.add_node(1, :foo, nil, [])
      g.add_node(2, :bar, nil, [1])
      assert_equal [], g[1].slashes
      assert_equal [g[1]], g[2].slashes
    end

    def test_slash_storage_out_of_sequence
      ValidatingDependencyGraph.new do |g|
        g.badd_node(2, :bar, nil, [1])
        g.badd_node(1, :foo, nil, [])
      end
    end

    def test_subgraph
      g = ValidatingDependencyGraph.new
      g.add_node(1, :foo, nil)
      g.add_node(11, :bar, 1)
      g.add_node(111, :bar, 11, [11])
      g.add_node(12, :bar, 1)
      g.add_node(121, :bar, 12, [11])
      g.add_node(1211, :bar, 121, [121])

      assert_equal [1, 11, 12, 111, 121, 1211], g[1].subgraph.collect(&:identifier).sort
      assert_equal [11, 111], g[11].subgraph.collect(&:identifier).sort
      assert_equal [111], g[111].subgraph.collect(&:identifier).sort
      assert_equal [12, 121, 1211], g[12].subgraph.collect(&:identifier).sort
      assert_equal [121, 1211], g[121].subgraph.collect(&:identifier).sort
      assert_equal [1211], g[1211].subgraph.collect(&:identifier).sort
    end

    def test_all_slashes_contained
      g = ValidatingDependencyGraph.new
      g.add_node(1, :foo, nil)
      g.add_node(11, :bar, 1)
      g.add_node(111, :bar, 11, [11])
      g.add_node(12, :bar, 1)
      g.add_node(121, :bar, 12, [11])

      assert_equal true, g[1].all_slashes_contained?
      assert_equal true, g[11].all_slashes_contained?
      assert_equal false, g[111].all_slashes_contained?
      assert_equal false, g[12].all_slashes_contained?
      assert_equal false, g[121].all_slashes_contained?
    end

    def test_min_max_token_number
      g = setup_ok_graph
      assert_equal 1, g[250398].min_token_number
      assert_equal 8, g[250398].max_token_number

      assert_equal 1, g[250414].min_token_number
      assert_equal 19, g[250414].max_token_number

      g = ValidatingDependencyGraph.new
      g.add_node(1, :foo, nil, [], { :empty => true, :token_number => 600 })
      g.add_node(2, :foo, 1, [], { :empty => false, :token_number => 10 })
      assert_equal 10, g[1].max_token_number
      assert_equal 10, g[2].max_token_number

      g = ValidatingDependencyGraph.new
      g.add_node(1, :foo, nil, [], { :empty => true, :token_number => 600 })
      g.add_node(2, :foo, 1, [], { :empty => true, :token_number => 10 })
      assert_equal nil, g[1].max_token_number
      assert_equal nil, g[2].max_token_number
    end

    def test_linearly_precedes
      g = setup_ok_graph
      assert_equal true, g[250398].linearly_precedes?(g[250406])
      assert_equal false, g[250406].linearly_precedes?(g[250398])

      # 250399 occurs second within 250398's subgraph
      assert_equal false, g[250399].linearly_precedes?(g[250398])
      assert_equal false, g[250398].linearly_precedes?(g[250399])

      # 250414's subgraph contains 250398
      assert_equal false, g[250414].linearly_precedes?(g[250398])
      assert_equal false, g[250398].linearly_precedes?(g[250414])
    end

    def test_proiel_validation
      g = setup_ok_graph
      assert_equal true, g.valid?(EMITTER)
    end

    def test_proiel_validation_root_daughters
      # Break the graph by adding an ADV directly under the root
      g = ValidatingDependencyGraph.new
      g.add_node(250414, "adv", nil, [], { :empty => false, :morphtag => MorphTag.new('') })
      g.add_node(250398, "adv", 250414, [], { :empty => false, :morphtag => MorphTag.new('') })
      assert_equal false, g.valid?
    end


    def test_proiel_validation_multiple_preds_or_vocs
      # Check multiple PREDs under the root
      g = ValidatingDependencyGraph.new
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1, :morphtag => MorphTag.new('')})
      g.add_node(2, :pred, nil, [], { :empty => false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(3, :pred, nil, [], { :empty => false, :token_number => 3, :morphtag => MorphTag.new('')})
      g.add_node(4, :pred, nil, [], { :empty => false, :token_number => 4, :morphtag => MorphTag.new('')})
      g.add_node(5, :pred, nil, [], { :empty => false, :token_number => 5, :morphtag => MorphTag.new('')})
      g.add_node(6, :pred, nil, [], { :empty => false, :token_number => 6, :morphtag => MorphTag.new('')})
      assert_equal true, g.valid?

      # Switch the order to see if the sorting is all right
      g = ValidatingDependencyGraph.new
      g.add_node(5, :pred, nil, [], { :empty => false, :token_number => 5, :morphtag => MorphTag.new('')})
      g.add_node(6, :pred, nil, [], { :empty => false, :token_number => 6, :morphtag => MorphTag.new('')})
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1, :morphtag => MorphTag.new('')})
      g.add_node(2, :pred, nil, [], { :empty => false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(4, :pred, nil, [], { :empty => false, :token_number => 4, :morphtag => MorphTag.new('')})
      g.add_node(3, :pred, nil, [], { :empty => false, :token_number => 3, :morphtag => MorphTag.new('')})
      assert_equal true, g.valid?

      # Try expanding the subgraphs somewhat, intermix vocs and preds and
      # add a slash to the mix
      g = ValidatingDependencyGraph.new
      g.add_node(5, :pred, nil, [], { :empty => false, :token_number => 6, :morphtag => MorphTag.new('V')})
      g.add_node(51, :adv, 5, [],   { :empty => false, :token_number => 7, :morphtag => MorphTag.new('')})
      g.add_node(6, :pred, nil, [], { :empty => false, :token_number => 8, :morphtag => MorphTag.new('V')})
      g.add_node(61, :adv, 6, [], { :empty => false, :token_number => 10, :morphtag => MorphTag.new('V')})
      g.add_node(611, :xadv, 61, [61], { :empty => false, :token_number => 9, :morphtag => MorphTag.new('')})
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1, :morphtag => MorphTag.new('')})
      g.add_node(2, :voc, nil, [], { :empty => false, :token_number => 3, :morphtag => MorphTag.new('C')})
      g.add_node(21, :voc, 2, [], { :empty => false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(22, :voc, 2, [], { :empty => false, :token_number => 4, :morphtag => MorphTag.new('')})
      assert_equal true, g.valid?(EMITTER)

      # Violate the constraint by having one pred subgraph overlap with the pred after it.
      g = ValidatingDependencyGraph.new
      g.add_node(5, :pred, nil, [], { :empty => false, :token_number => 6, :morphtag => MorphTag.new('V')})
      g.add_node(51, :adv, 5, [],   { :empty => false, :token_number => 4, :morphtag => MorphTag.new('')})
      g.add_node(6, :pred, nil, [], { :empty => false, :token_number => 8, :morphtag => MorphTag.new('V')})
      g.add_node(61, :adv, 6, [], { :empty => false, :token_number => 10, :morphtag => MorphTag.new('V')})
      g.add_node(611, :adv, 61, [], { :empty => false, :token_number => 9, :morphtag => MorphTag.new('')})
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1, :morphtag => MorphTag.new('')})
      g.add_node(2, :pred, nil, [], { :empty => false, :token_number => 3, :morphtag => MorphTag.new('')})
      g.add_node(21, :pred, 2, [], { :empty => false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(22, :pred, 2, [], { :empty => false, :token_number => 5, :morphtag => MorphTag.new('')})
      assert_equal false, g.valid?

      # Check that empty nodes, whose linearisation does not matter, do not 
      # overlap violations.
      g = ValidatingDependencyGraph.new
      g.add_node(5, :pred, nil, [], { :empty => true, :token_number => 600, :morphtag => MorphTag.new('V')})
      g.add_node(51, :adv, 5, [],   { :empty => false, :token_number => 5, :morphtag => MorphTag.new('')})
      g.add_node(6, :pred, nil, [], { :empty => false, :token_number => 8, :morphtag => MorphTag.new('V')})
      g.add_node(61, :adv, 6, [], { :empty => false, :token_number => 10, :morphtag => MorphTag.new('V')})
      g.add_node(611, :adv, 61, [], { :empty => false, :token_number => 9, :morphtag => MorphTag.new('')})
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1, :morphtag => MorphTag.new('')})
      g.add_node(2, :voc, nil, [], { :empty => false, :token_number => 3, :morphtag => MorphTag.new('C')})
      g.add_node(21, :voc, 2, [], { :empty => false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(22, :voc, 2, [], { :empty => false, :token_number => 4, :morphtag => MorphTag.new('')})
      assert_equal true, g.valid?(EMITTER)
      
      # Violate the constraint by having the slash point to a different subgraph
      g = ValidatingDependencyGraph.new
      g.add_node(5, :pred, nil, [], { :empty => false, :token_number => 6, :morphtag => MorphTag.new('')})
      g.add_node(51, :adv, 5, [],   { :empty => false, :token_number => 7, :morphtag => MorphTag.new('')})
      g.add_node(6, :pred, nil, [], { :empty => false, :token_number => 8, :morphtag => MorphTag.new('')})
      g.add_node(61, :adv, 6, [], { :empty => false, :token_number => 10, :morphtag => MorphTag.new('')})
      g.add_node(611, :xadv, 61, [5], { :empty => false, :token_number => 9, :morphtag => MorphTag.new('')})
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1, :morphtag => MorphTag.new('')})
      g.add_node(2, :voc, nil, [], { :empty => false, :token_number => 3, :morphtag => MorphTag.new('C')})
      g.add_node(21, :voc, 2, [], { :empty => false, :token_number => 2, :morphtag => MorphTag.new('')})
      g.add_node(22, :voc, 2, [], { :empty => false, :token_number => 4, :morphtag => MorphTag.new('')})
      assert_equal false, g.valid?
    end

    def test_visualise
      g = setup_ok_graph
      g.visualize
      g.visualise
    end

    def test_relinearisation
      g = ValidatingDependencyGraph.new
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 2})
      g.add_node(11, :sub, 1, [],   { :empty => false, :token_number => 1})
      g.add_node(12, :adv, 1, [], { :empty => false, :token_number => 3})
      g.add_node(121, :adv, 12, [], { :empty => false, :token_number => 0})
      g.add_node(122, :adv, 12, [], { :empty => false, :token_number => 4})
      assert_equal [:root, 11, 1, 121, 12, 122], g.relinearise.collect(&:identifier)
    end

    def test_all_slashes
      # Simple, ordinary case: a non-empty xobj with a slash
      g = ValidatingDependencyGraph.new
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1})
      g.add_node(11, :adv, 1, [], { :empty => false, :token_number => 2})
      g.add_node(12, :xobj, 1, [1], { :empty => false, :token_number => 3})
      assert_equal g[1].all_slashes.length, 0
      assert_equal g[11].all_slashes.length, 0
      assert_equal g[12].all_slashes.length, 1

      # A pair of coordinated non-empty xobjs sharing a slash
      g = ValidatingDependencyGraph.new
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1})
      g.add_node(11, :adv, 1, [], { :empty => false, :token_number => 2})
      g.add_node(12, :xobj, 1, [1], { :empty => false, :token_number => 3, :morphtag => PROIEL::MorphTag.new('C')})
      g.add_node(121, :xobj, 12, [], { :empty => false, :token_number => 5})
      g.add_node(122, :xobj, 12, [], { :empty => false, :token_number => 6})
      assert_equal g[1].all_slashes.length, 0
      assert_equal g[11].all_slashes.length, 0
      assert_equal g[12].all_slashes.length, 1
      assert_equal g[121].slashes.length, 0
      assert_equal g[122].slashes.length, 0 
      assert_equal g[121].all_slashes.length, 1
      assert_equal g[122].all_slashes.length, 1

      # A pair of coordinated non-empty xobjs sharing a slash but with an empty coordinator
      g = ValidatingDependencyGraph.new
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1})
      g.add_node(11, :adv, 1, [], { :empty => false, :token_number => 2})
      g.add_node(12, :xobj, 1, [1], { :empty => true, :token_number => 3})
      g.add_node(121, :xobj, 12, [], { :empty => false, :token_number => 5})
      g.add_node(122, :xobj, 12, [], { :empty => false, :token_number => 6})
      assert_equal g[1].all_slashes.length, 0
      assert_equal g[11].all_slashes.length, 0
      assert_equal g[12].all_slashes.length, 1
      assert_equal g[121].slashes.length, 0
      assert_equal g[122].slashes.length, 0 
      assert_equal g[121].all_slashes.length, 1
      assert_equal g[122].all_slashes.length, 1

      # Full-fledged multi-level inheritance with empty coordinator
      g = ValidatingDependencyGraph.new
      g.add_node(1, :pred, nil, [], { :empty => false, :token_number => 1})
      g.add_node(11, :adv, 1, [], { :empty => false, :token_number => 2})
      g.add_node(12, :xobj, 1, [1], { :empty => true, :token_number => 3})
      g.add_node(121, :xobj, 12, [], { :empty => false, :token_number => 4, :morphtag => PROIEL::MorphTag.new('C')})
      g.add_node(1211, :xobj, 121, [], { :empty => false, :token_number => 5})
      g.add_node(1212, :xobj, 121, [], { :empty => false, :token_number => 6})
      g.add_node(122, :xobj, 12, [], { :empty => false, :token_number => 7, :morphtag => PROIEL::MorphTag.new('C')})
      g.add_node(1221, :xobj, 122, [], { :empty => false, :token_number => 8})
      g.add_node(1222, :xobj, 122, [], { :empty => false, :token_number => 9})
      assert_equal g[1].all_slashes.length, 0
      assert_equal g[11].all_slashes.length, 0
      assert_equal g[12].all_slashes.length, 1
      assert_equal g[121].slashes.length, 0
      assert_equal g[1211].slashes.length, 0
      assert_equal g[1212].slashes.length, 0 
      assert_equal g[122].slashes.length, 0
      assert_equal g[1221].slashes.length, 0
      assert_equal g[1222].slashes.length, 0 
      assert_equal g[121].all_slashes.length, 1
      assert_equal g[1211].all_slashes.length, 1
      assert_equal g[1212].all_slashes.length, 1 
      assert_equal g[122].all_slashes.length, 1
      assert_equal g[1221].all_slashes.length, 1
      assert_equal g[1222].all_slashes.length, 1 
    end
  end
end
