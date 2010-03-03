#--
#
# lfg.rb - Functions for converting PROIEL data structures to XLE compatible representations
#
# Copyright 2009 Marius L. Jøhndal
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

require 'set'

module LFG
  class SemanticForm
    def initialize(pred_sem, arguments = [], ns_arguments = [])
      @pred_sem = pred_sem.downcase
      @arguments = arguments
      @ns_arguments = ns_arguments
    end

    def to_s
      "'#{@pred_sem}<#{@arguments.join(',')}>#{@ns_arguments.join(',')}'"
    end

    def ==(o)
      self.to_s == o.to_s # cheating, but simple
    end
  end

  class SemanticPROForm < SemanticForm
    def initialize
    end

    def to_s
      "'PRO'"
    end
  end

  class SetValue < Set
    def to_s
      "{#{map(&:to_s).join(', ')}}"
    end
  end

  class AVM < Hash
    # Not real unification, but close enough: 1) hash merging with key conflict check,
    # 2) returns new object instead of modifying existing one.
    def unify(o)
      n = o.dup
      (self.keys & n.keys).each do |shared_attribute|
        x, y = self[shared_attribute], n[shared_attribute]
        if x.is_a?(SetValue) and y.is_a?(SetValue)
          n[shared_attribute] = x + y # stuff the set union in dup'ed o
        else
          raise "unification failed on attribute #{shared_attribute}: #{x} != #{y}" unless x == y
        end
      end
      self.merge(n)
    end

    def to_s
      "[#{map { |*av| av.join(': ') }.join(', ')}]"
    end

    def ==(o)
      self.to_s == o.to_s # cheating, but simple
    end

    # Removes all AV pairs with a nil value.
    def compact!
      delete_if { |attribute, value| value.nil? }
    end
  end

  class FStructure
    def initialize(graph)
      raise ArgumentError, "invalid graph" unless graph.is_a?(PROIEL::ValidatingDependencyGraph)

      @avm = convert_node(graph.root)
    end

    def to_s
      @avm.to_s
    end

    private

    IMPERSONALS = [ 'paeniteo' ]

    # 'Patches' a PROIEL subcategorisation frame.
    def self.patch_frame(frame, lemma, passive_swap = false)
      returning(frame.dup) do |frame|
        # 'Undo' passivisation by demoting any sub to obj and promoting any
        # ag to subj.
        if passive_swap
          # Demoting sub to obj is equivalent to adding obj unless it already
          # exists or it is an impersonal, since, by stipulation, we always
          # have a sub unless it is an impersonal.
          frame << :obj unless frame.include?(:sub) or IMPERSONALS.include?(lemma.lemma)

          # Promoting ag to sub is equivalent to deleting ag and adding
          # sub, since, by stipulation, we always have a sub unless it is
          # an impersonal.
          frame.delete(:ag)
          frame << :sub unless frame.include?(:sub) or IMPERSONALS.include?(lemma.lemma)
        else
          # If is missing a subj function, prepend it since this is almost
          # certainly correct (modulo a black-list for impersonal verbs).
          frame << :sub unless frame.include?(:sub) or IMPERSONALS.include?(lemma.lemma)
        end
      end
    end

    # 'Patches' PROIEL subcategorisation frames.
    #
    # Does not eliminate identical frames.
    def self.patch_frames(frames, lemma, passive_swap)
      frames.map do |frame, frequency|
        [patch_frame(frame, lemma, passive_swap), frequency]
      end
    end

    RELATION_TO_FUNCTION_MAP = {
      :sub     => :subj,
      :obj     => :obj,
      :obl     => :obl,
      :apos    => :adj,
      :atr     => :adj,
      :adv     => :adj,
      :narg    => :obl,
      :ag      => :obl,
      :xadv    => :xadj,
      :xobj    => :xobj,

      # TODO
      :comp    => nil,
      :piv     => nil,

      # Rare. We don't bother.
      :adnom   => nil,
      :arg     => nil,
      :nonsub  => nil,
      :part    => nil,
      :per     => nil,
      :rel     => nil,

      # Unmappable. Should result in an error.
      :voc     => nil,
      :parpred => nil,
      :pred    => nil,
      :aux     => nil,
    }

    MORPHOLOGY_MAPS = {
      :tense => {
        :p => :pres,
        :i => :past,
        :l => :past,
        :f => :fut,
        :r => :past,
        :t => :fut,

        # Undefined for Latin
        :a => :past,
        :s => :past,
        :u => :past,
      },
      :tense_aspect => {
        :p => :imperf, # present
        :i => :imperf, # imperfect
        :l => :perf,   # pluperfect
        :f => :imperf, # future
        :r => nil,     # perfect
        :t => :perf,   # future perfect

        # Undefined for Latin
        :a => :perf,
        :s => :perf,
        :u => :perf,
      },
      :case => {
        :n => :nom,
        :v => :voc,
        :a => :acc,
        :g => :gen,
        :d => :dat,
        :b => :abl,

        # Undefined for Latin
        :i => :ins,
        :l => :loc,
        :c => :gen_dat, #TODO
      },
      :number => {
        :s => :sg,
        :p => :pl,

        # Undefined for Latin
        :d => :dual,
      },
      :gender => {
        :o => :m_n, # TODO
        :p => :m_f, # TODO
        :q => :m_f_n, # TODO
        :r => :f_n, # TODO
        :m => :masc,
        :f => :fem,
        :n => :neut,
      },
      :person => {
        1 => 1,
        2 => 2,
        3 => 3,
      },
    }

    # Functions that appear in our semantic forms. This serves a dual
    # purpose: it is used to filter for governable grammatical functions
    # and it is used to order functions in the order we prefer to have
    # them.
    FUNCTIONAL_PRESENTATION_ORDER = [:subj, :obj, :xobj, :obl]

    # Converts PROIEL morphology to LFG morphological features.
    def convert_morphology(node, morphtag_field, mapping_field = nil)
      MORPHOLOGY_MAPS[mapping_field || morphtag_field][node.data[:morphtag][morphtag_field]]
    end

    # Converts a PROIEL subcategorisation fram to an LFG-compatible
    # subcategorisation frame.
    def self.convert_subcategorisation_frame(frame)
      frame.map do |relation|
        # Map relations to LFG functions
        RELATION_TO_FUNCTION_MAP[relation]
      end.select do |relation|
        # Include only governable GFs
        FUNCTIONAL_PRESENTATION_ORDER.include?(relation)
      end.compact.sort_by do |relation|
        # Sort in a more human-readable way
        FUNCTIONAL_PRESENTATION_ORDER.index(relation)
      end
    end

    # Merges two arrays of LFG-compatible subcategorisation frames and
    # their frequencies. The merged frames are returned as an array of
    # frames sorted by decreasing frequency.
    def self.merge_subcategorisation_frames(frames)
      frames.inject({}) do |frames, frame_frequency|
        # Merge identical frame frequencies
        frame, frequency = frame_frequency
        frames[frame] ||= 0
        frames[frame] += frequency
        frames
      end.sort_by do |frame, frequency|
        # Sort frames by decreasing frequency
        -frequency
      end
    end

    # Converts PROIEL subcategorisation frames and frequencies to
    # LFG-compatible subcategorisation frames and frequencies. The frames
    # are returned as an array of frames sorted by decreasing frequency.
    def self.convert_subcategorisation_frames(frames)
      merge_subcategorisation_frames(frames.map do |frame, frequency|
        [convert_subcategorisation_frame(frame), frequency]
      end)
    end

    # Looks up the subcat frames for a lemma.
    def self.lookup_lemma_subcategorisation_frames(lemma)
      # Cache frames. Keep both active and passive frame lists for
      # debugging purposes.
      @@lemma_subcategorisation_frames ||= {}
      @@lemma_subcategorisation_frames[lemma] ||=
        merge_subcategorisation_frames(convert_subcategorisation_frames(FStructure.patch_frames(lemma.subcategorisation_frames(:voice => 'a'), lemma, false)) +
        convert_subcategorisation_frames(FStructure.patch_frames(lemma.subcategorisation_frames(:voice => 'p'), lemma, true)))
    end

    # Looks up the subcat frame for a token.
    def self.lookup_token_subcategorisation_frame(token)
      passive_swap = false
      FStructure.convert_subcategorisation_frame(FStructure.patch_frame(token.subcategorisation_frame, token.lemma, passive_swap))
    end

    # Looks up a semantic form for a node
    def lookup_semantic_form(node)
      token = Token.find(node.identifier)       #TODO: dirty!
      lemma = token.lemma                       #TODO: dirty!

      case lemma.pos.first
      when 'V'
        # TODO: what should we do? 1) introduce subj in all candidate frames
        # and the token's frame first, then intersect them, 2) introduce it
        # in the token's frame, then intersect, 3) introduce it in
        # candidate frames, then intersect. There are pros and cons for all
        # of these.

        # Grab our overt frame.
        overt_frame = FStructure.lookup_token_subcategorisation_frame(token)

        # Filter candidate frames based on overt frame
        candidate_frames = FStructure.lookup_lemma_subcategorisation_frames(lemma).select do |frame, frequency|
          overt_frame.all? { |function| frame.include?(function) }
        end

        # Verify that there is indeed at least one frame in the candidate
        # list. (If not, we have messed up when we inserted subj).
        unless candidate_frames.length > 0
          raise "Subcategorisation frame guessing failed for #{node.data[:form]} (#{lemma.lemma}, #{lemma.id})."
        end

        # Grab the most frequent remaining frame.
        chosen_frame = candidate_frames.first.first

        SemanticForm.new(lemma.lemma, chosen_frame)
      when 'P'
        SemanticPROForm.new
      else
        # Last ditch effort
        SemanticForm.new(lemma.lemma)
      end
    end

    def interpret_node(node)
      case (node.is_root? ? :root : node.relation)
      when :root
        AVM.new
      when :pred
        returning(AVM[
          :tense => convert_morphology(node, :tense),
          :aspect => convert_morphology(node, :tense, :tense_aspect),
          :pred => lookup_semantic_form(node),
        ]) do |avm|
          # Remove any nil values we have. This will happen if any of the morphology
          # features are undefined.
          avm.compact!
        end
      when :sub, :obj, :obl, :apos, :atr, :adv, :narg, :ag, :xobj
        returning(AVM[
          :case => convert_morphology(node, :case), #TODO: pcase
          :num => convert_morphology(node, :number),
          :gend => convert_morphology(node, :gender),
          :pers => convert_morphology(node, :person),
          :pred => lookup_semantic_form(node),
        ]) do |avm|
          # Remove any nil values we have. This will happen if any of the morphology
          # features are undefined.
          avm.compact!
        end
      when :aux
        AVM.new # TODO
      else
        raise "Unknown relation #{node.relation}"
      end
    end

    def convert_node(node)
      n = node.dependents.map { |n| convert_node(n) }.inject(interpret_node(node)) { |s, i| s.unify(i) }

      case (node.is_root? ? :root : node.relation)
      when :root, :pred, :aux
        n
      when :sub, :obj, :obl, :narg, :ag, :xobj
        AVM[RELATION_TO_FUNCTION_MAP[node.relation] => n]
      when :apos, :atr, :adv, :xadv
        AVM[RELATION_TO_FUNCTION_MAP[node.relation] => SetValue[n]]
      else
        raise "Unknown relation #{node.relation}"
      end
    end
  end
end

if $0 == __FILE__
  require 'config/environment'

  # 12975, 14673: should be flattened
  [12668, 12669, 12731, 12812, 10311, 12975, 14673].each do |sentence_id|
    s = Sentence.find(sentence_id)
    puts "#{s.id}: #{s.tokens.map(&:form).join(' ')}"
    puts LFG::FStructure.new(s.dependency_graph)
    puts
  end

  # Iterate all Latin verbal lemmata and pretty-print their LFG subcat
  # frames.
  Lemma.find_all_by_lemma('tempto').each do |lemma|
    frames = LFG::FStructure.lookup_lemma_subcategorisation_frames(lemma)
    puts "Frames for #{lemma.export_form}:"
    frames.each do |frame, frequency|
      puts "  [" + [frame.join(', '), frequency].join(': ') + "]"
    end
    puts
  end
end
