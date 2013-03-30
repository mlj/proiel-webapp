# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 University of Oslo
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

module PROIEL
  class DependencyGraphNode
    attr_reader :relation
    attr_reader :head
    attr_reader :identifier
    attr_accessor :data

    def initialize(identifier, relation, head, data = {})
      @identifier = identifier
      @relation = relation ? relation.to_s.to_sym : nil
      @data = data
      @head = head
      @dependents = {}
      @slashes = {}
    end

    def add_dependent(node)
      @dependents[node.identifier] = node
    end

    def remove_dependent(identifier)
      @dependents.delete(identifier)
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
        s = ' ' * indentation + "[#{identifier}: #{relation.inspect}, #{data.inspect} | #{slashes.map(&:identifier).inspect}] -> {\n"
        dependents.each { |d| s += d.inspect_subgraph(indentation + 2) }
        s += ' ' * indentation + "}\n"
        s
      else
        ' ' * indentation + "[#{identifier}: #{relation.inspect}, #{data.inspect} | #{slashes.map(&:identifier).inspect}]\n"
      end
    end

    def each_dependent(&block)
      raise ArgumentError, "Block expected" unless block_given?

      dependents.each do |d|
        block.call(d)
        d.each_dependent(&block)
      end
    end

    def add_slash(slashee_node, interpretation)
      @slashes[slashee_node] = interpretation
    end

    def has_slash?
      !@slashes.empty?
    end

    alias :has_slashes? :has_slash?

    # Returns an array with the the slashees of this node.
    def slashes
      @slashes.keys
    end

    # Returns a hash with the the slashees of this node and their
    # relation to this node.
    def slashes_with_interpretations
      @slashes
    end

    def is_empty?
      (@data[:empty] or identifier == :root) ? true : false
    end

    def token_number
      @data[:token_number]
    end

    # A hack, but it works. Graphs that are initialized with
    # new_from_editor will have @data[:pos], whereas graphs that are
    # initialized from the database will have a full morph_features
    # object.
    def pos
      if @data[:morph_features]
        @data[:morph_features].pos_s
      elsif @data[:pos]
        @data[:pos]
      else
        nil
      end
    end

    # Returns +true+ if this node is a coordination node or
    # a potential coordination node, i.e. a conjunction or an
    # empty node (which might be an asyndetic conjunction).
    def is_coordinator?
      pos == 'C-' or @data[:empty] == 'C'
    end

    # Returns +true+ if this node is a verbal node or a potential
    # verbal node, i.e. a verb, an empty node or something with
    # the relation PRED.
    def is_verbal?
      pos == 'V-' or @data[:empty] == 'V' or relation == :pred
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

    # Returns an array of the node's slashees, either on the node itself
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

    # Returns the interpretation of a slash -- existing or potential --
    # from the node to another node +slashee+.
    def interpret_slash(slashee)
      raise ArgumentError, "invalid slashee" if slashee.blank?

      if self.is_empty? and self.is_verbal? and slashee.is_verbal? and self.relation == slashee.relation
        :pid
      elsif [:xadv, :xobj].include?(self.relation)
        :xsub
      else
        raise ArgumentError, "slashee has no relation" if slashee.relation.blank?
        slashee.relation
      end
    end

    def to_h
      { :dependents => Hash[*dependents.collect { |d| [d.identifier, d.to_h] }.flatten],
        :relation => @relation,
        :empty => @data[:empty],
        :slashes => slashes.map(&:identifier),
      }
    end
  end

  class DependencyGraph
    attr_reader :root

    def initialize(options = {})
      @nodes = {}
      @root = DependencyGraphNode.new(:root, nil, nil)

      if block_given?
        @postponed_nodes = {}

        yield self

        # Traverse the stored postponed nodes and add them
        add_postponed_subgraph

        # Add in the slashes if we are about to end the recursion
        @postponed_nodes.each_pair do |identifier, values|
          next unless values[:slashes_and_interpretations]
          values[:slashes_and_interpretations].each do |slash_id, slash_interpretation|
            @nodes[identifier].add_slash(@nodes[slash_id], slash_interpretation || @nodes[identifier].interpret_slash(@nodes[slash_id]))
          end
        end

        @postponed_nodes = nil
      end
    end

    private

    def add_postponed_subgraph(identifier = :root, head_identifier = nil)
      node = @postponed_nodes[identifier]
      # Add nodes without their slashes
      add_node(identifier, node[:relation], head_identifier, {}, node[:data]) unless identifier == :root
      node[:dependent_ids].each { |dependent_id| add_postponed_subgraph(dependent_id, identifier) }
    end

    public

    def [](identifier)
      @nodes[identifier]
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

    def badd_node(identifier, relation, head_identifier = nil, slashes_and_interpretations = {}, data = {})
      # Merge data about this token into the result structure
      @postponed_nodes[identifier] ||= { :dependent_ids => [] }
      @postponed_nodes[identifier].merge!({ :relation => relation, :data => data })

      # Attach this token to its head's list of dependents
      head_identifier ||= :root
      @postponed_nodes[head_identifier] ||= { :dependent_ids => [] }
      @postponed_nodes[head_identifier][:dependent_ids] << identifier

      @postponed_nodes[identifier].tap do |n|
        n[:slashes_and_interpretations] = slashes_and_interpretations
      end
    end

    def add_node(identifier, relation, head_identifier = nil, slash_ids_and_interpretations = {}, data = {})
      if @nodes[identifier]
        raise "Node with ID #{identifier} already exists"
      else
        if head_identifier and head_identifier != :root
          raise "Head node with ID #{head_identifier} does not exist" unless @nodes[head_identifier]
          @nodes[identifier] = DependencyGraphNode.new(identifier, relation, @nodes[head_identifier], data)
          @nodes[head_identifier].add_dependent(@nodes[identifier])
        else
          @nodes[identifier] = DependencyGraphNode.new(identifier, relation, @root, data)
          @root.add_dependent(@nodes[identifier])
        end
      end

      slash_ids_and_interpretations.each do |i, interpretation|
        raise "Slash node with ID #{i} does not exist" unless @nodes[i]
        raise "Slash to node with ID #{i} does not have an interpretation" if interpretation.blank?
        @nodes[identifier].add_slash(@nodes[i], interpretation)
      end

      @nodes[identifier]
    end

    def remove_node(identifier)
      identifier = identifier.to_i
      node = @nodes[identifier]
      return unless node   # Will happen if the prodrop token was not saved before it was removed

      if node.head
        @nodes[node.head.identifier].remove_dependent(identifier)
      end
      @nodes.delete(identifier)
    end

    def valid?
      # FIXME: check for cycles
      true
    end

    def inspect
      root.inspect_subgraph
    end

    def to_h
      @root.to_h[:dependents]
    end

    def self.new_from_editor(editor_output)
      DependencyGraph.new do |g|
        (rec = lambda do |subtree, head_id|
          unless subtree.nil?
            subtree.each_pair do |id, values|
              data = { :empty => values['empty'], :pos => values['pos'] }
              slashes = {}
              (values['slashes'] || []).each { |s| slashes[id_to_i(s)] = nil }
              g.badd_node(id_to_i(id), values['relation'], head_id, slashes, data)
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

    HEAD_DEPENDENT_CONSTRAINTS = {
      # FIXME: ATR should be excluded from anything but participles
      :V => [:adv, :ag, :apos, :arg, :aux, :comp, :nonsub, :obj, :obl, :per, :piv, :sub, :xadv, :xobj, :atr, :part],
      :N => [:adnom, :apos, :atr, :aux, :comp, :narg, :part, :rel],
      :A => [:adv, :apos, :atr, :aux, :comp, :obl, :part],
      :P => [:apos, :atr, :aux, :part, :rel],
    }

    def valid?(msg_handler = lambda { |token_ids, msg| })
      #FIXME
      @valid = true
      @msg_handler = msg_handler

      test_token('Must have or inherit one outgoing slash edge', :is_open?) do |t|
        t.all_slashes.length == 1
      end

      # Root daughters may be PREDs, VOCs or PARPREDs
      test_token('May not be a daughter of the root node', :is_daughter_of_root?) do |t|
        [:pred, :parpred, :voc].include?(t.relation)
      end

      test_tokens('There can only be one PRED node under the root',
                  lambda { |t| t.is_daughter_of_root? and t.relation == :pred } ) do |ts|
        ts.size < 2 ? [] : ts
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

      test_token("A subjunction may only be the dependent in a COMP, ADV, AUX, ATR or APOS relation",
                 lambda { |t| t.pos == 'G-' }) do |t|
        t.relation == :comp or t.relation == :adv or t.relation == :apos or t.relation == :aux or t.relation == :atr
      end

      nodes.select { |t| t.has_slashes? and t.slashes.any?(&:nil?) }.each do |t|
        @valid = false
        @msg_handler.call([t.identifier], "All slashes must point to tokens in the same sentence")
      end

      #FIXME: special handling of non-part. vs. part.
      #FIXME: empty nodes can be verbs, but have to be excluded for now
      HEAD_DEPENDENT_CONSTRAINTS.each_pair do |pos_major, relations|
        test_head_dependent(pos_major, *relations)
      end

      #FIXME
      @valid
    end

    private

    # Verifies that all tokens that match the morphtag mask only have dependents related
    # to it by one of the given relations.
    def test_head_dependent(pos_major, *dependent_relations)
      test_token("may only be the head in a #{dependent_relations.to_sentence(:words_connector => ', ', :two_words_connector => ' or ', :last_word_connector => ', or ')} relation",
                 lambda { |t| !t.is_empty? and t.data[:morph_features].lemma.part_of_speech.major == pos_major }) do |t|
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
