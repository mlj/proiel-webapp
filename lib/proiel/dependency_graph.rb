#!/usr/bin/env ruby
#
# dependency_graph.rb - Dependency graph manipulation and validation
#
# Written by Marius L. Jøhndal, 2007, 2008.
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
    attr_reader :slashes

    def initialize(identifier, relation, head, data = {})
      @identifier = identifier
      @relation = relation ? relation.to_sym : nil
      @data = data
      @head = head
      @dependents = {}
      @slashes = []
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

    # Returns +true+ if this node is a daughter of the root node.
    def is_daughter_of_root?
      head and head.is_root?
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

    private

    def add_postponed_subgraph(identifier = :root, head_identifier = nil)
      node = @postponed_nodes[identifier]
      add_node(identifier, node[:relation], head_identifier, [], node[:data]) unless identifier == :root
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

    # Returns an array with all the node identifiers.
    def identifiers
      nodes.map(&:identifier)
    end

    def badd_node(identifier, relation, head_identifier = nil, slash_ids = [], data = {})
      # Merge data about this token into the result structure
      @postponed_nodes[identifier] ||= { :dependent_ids => [] }
      @postponed_nodes[identifier].merge!({ :relation => relation, :data => data })

      # Attach this token to its head's list of dependents
      head_identifier ||= :root
      @postponed_nodes[head_identifier] ||= { :dependent_ids => [] }
      @postponed_nodes[head_identifier][:dependent_ids] << identifier

      returning @postponed_nodes[identifier] do |n|
        n[:slash_ids] = slash_ids
      end
    end

    def add_node(identifier, relation, head_identifier = nil, slash_ids = [], data = {})
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

      slash_ids.each do |i|
        raise "Slash node with ID #{i} does not exist" unless @nodes[i]
        @nodes[identifier].add_slash(@nodes[i])
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
end

module PROIEL
  class ValidatingDependencyGraphNode < Lingua::DependencyGraphNode
    def is_empty?
      @data[:empty] or identifier == :root
    end

    def token_number
      @data[:token_number]
    end

    def pos
      @data[:morphtag] ? @data[:morphtag].pos_to_s : nil
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
      if self.is_empty? and self.is_verbal? and slashee.is_verbal? and self.relation == slashee.relation
        "predicate-identity"
      elsif [:xadv, :piv, :xobj].include?(self.relation)
        "subject"
      else
        slashee.relation
      end
    end

    # Returns a `relinearisation' of the subgraph constituted by this node and its dependents.
    def relinearise
      n = [self] + dependents
      n.sort_by { |t| t.token_number || -1 }.collect { |t| t == self ? self : t.relinearise }.flatten
    end

    def to_h
      { :dependents => Hash[*dependents.collect { |d| [d.identifier, d.to_h] }.flatten],
        :relation => @relation,
        :empty => @data[:empty],
        :slashes => slashes.map(&:identifier),
      }
    end
  end

  class ValidatingDependencyGraph < Lingua::DependencyGraph
    attr_reader :node_class

    def initialize
      @node_class = ValidatingDependencyGraphNode
      super
    end

    def to_h
      @root.to_h[:dependents]
    end

    def self.new_from_editor(editor_output)
      ValidatingDependencyGraph.new do |g|
        (rec = lambda do |subtree, head_id|
          unless subtree.nil?
            subtree.each_pair do |id, values|
              data = { :empty => values['empty'] }
              g.badd_node(id_to_i(id), values['relation'], head_id, (values['slashes'] || []).map { |x| id_to_i(x) }, data)
              rec[values['dependents'], id_to_i(id)]
            end
          end
        end)[editor_output, nil]
      end
    end

    private

    def self.id_to_i(id)
      id[/^new/] ? id : id.to_i
    end

    public

    # Produces an image visualising the dependency graph.
    #
    # ==== Options
    # fontname:: Forces the use of a particular font.
    # fontsize:: Forces the use of a particular font size.
    # linearized:: Visualises the graph in a linearized fashion.
    def visualize(format = :png, options = {})
      raise ArgumentError, "Invalid format #{format}" unless format == :png || format == :svg

      node_options = {}
      node_options[:fontname] = options[:fontname] if options[:fontname]
      node_options[:fontsize] = options[:fontsize] if options[:fontsize]

      Open3.popen3("dot -T#{format}") do |dot, img, err|
        options[:linearized] ? self.linearisation_dot(dot, node_options) : self.regular_dot(dot, node_options)
        @image = img.read
      end
      @image
    end

    protected

    EMPTY_NODE_STYLES = {
      'V' => { :label => 'V', :shape => 'circle', :fontcolor => 'black', },
      'C' => { :label => 'C', :shape => 'diamond', :fontcolor => 'black', },
      :root => { :label => '', :shape => 'circle', :fontcolor => 'black', },
    }

    def regular_dot(dot, node_options)
      @f = dot
      @f.puts "digraph G {"
      @f.puts "  charset=\"UTF-8\";"

      make_node(:root, node_options.merge({ :label => '', :shape => 'circle' }))

      @nodes.values.each do |node|
        identifier, relation, head, slashes = node.identifier, node.relation, node.head, node.slashes
        form, empty = node.data.values_at(:form, :empty)

        if empty
          make_node(identifier, node_options.merge(EMPTY_NODE_STYLES[empty]))
        elsif node.is_coordinator? and node.has_dependents?
          make_node(identifier, node_options.merge({ :label => form, :shape => 'diamond' }))
        else
          make_node(identifier, node_options.merge({ :label => form, :shape => 'box' }))
        end

        rel_colour = 'black'
        if head and relation
          make_edge(head.identifier, identifier,
                    node_options.merge({ :color => 'orange', :weight => 1.0,
                                         :label => relation.to_s.upcase, :fontcolor => rel_colour }))
        end

        slashes.each do |slashee|
          make_edge(identifier, slashee.identifier,
                    node_options.merge({ :label => node.interpret_slash(slashee).capitalize, :color => "blue", :fontcolor => "blue", :weight => 0.0, :style => "dashed" }))
        end
      end

      @f.puts "}"
      @f.close
    end

    def linearisation_dot(dot, node_options)
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
                    node_options.merge({ :label => node.interpret_slash(slashee).capitalize, :color => "blue", :fontcolor => "blue", :weight => 0.0, :style => "dotted" }))
        end
      end

      @nodes.values.reject(&:is_empty?).sort_by(&:token_number).each_cons(2) do |n1, n2|
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

    public

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
