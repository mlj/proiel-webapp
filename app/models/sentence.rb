# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

class Sentence < ActiveRecord::Base
  attr_accessible :sentence_number, :annotated_by, :annotated_at, :reviewed_by,
    :reviewed_at, :unalignable, :automatic_alignment, :sentence_alignment_id,
    :source_division_id, :assigned_to, :presentation_before, :presentation_after

  change_logging

  blankable_attributes :annotated_at, :annotated_by, :assigned_to,
    :automatic_alignment, :presentation_after, :presentation_before,
    :reviewed_at, :reviewed_by, :sentence_alignment_id

  belongs_to :source_division
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  belongs_to :annotator, :class_name => 'User', :foreign_key => 'annotated_by'
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewed_by'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to'

  belongs_to :sentence_alignment, :class_name => 'Sentence', :foreign_key => 'sentence_alignment_id'

  has_many :tokens, :dependent => :destroy

  # All tokens with dependents and information structure included
  has_many :tokens_with_dependents_and_info_structure, :class_name => 'Token',
     :include => [:dependents, :antecedent] do

    def with_prodrops_in_place
      prodrops, others = find(:all).partition { |token| token.empty_token_sort == 'P' }

      prodrops.each do |prodrop|
        head, head_index = others.each_with_index do |token, index|
          break [token, index] if token.id == prodrop.head_id
        end
        raise "No head found for prodrop element with ID #{prodrop.id}!" unless head

        relation = prodrop.relation.tag.to_s
        insertion_point = case relation
                          when 'sub'
                            # Position subjects before the verb
                            head_index

                          when 'obl'
                            if others[head_index + 1] && others[head_index + 1].relation &&
                                                      others[head_index + 1].relation.tag == 'obj'
                              # Position obliques after the object, if any,...
                              head_index + 2
                            else
                              # ...or otherwise after the verb
                              head_index + 1
                            end

                          when 'obj'
                            # Position objects after the verb
                            head_index + 1

                          else
                            raise "Unknown relation: #{relation}!"
                          end

        prodrop.form = 'PRO-' + relation.upcase
        others.insert(insertion_point, prodrop)
      end
      others
    end
  end

  # A sentence that has not been annotated.
  def self.unannotated
    where("annotated_by IS NULL")
  end

  # A sentences that has been annotated.
  def self.annotated
    where("annotated_by IS NOT NULL")
  end

  # A sentences that has not been reviewed.
  def self.unreviewed
    where("reviewed_by IS NULL")
  end

  # A sentence that has been reviewed.
  def self.reviewed
    where("reviewed_by IS NOT NULL")
  end

  # A sentences that belongs to a source.
  def self.by_source(source)
    where(:source_division_id => source.source_divisions.map(&:id))
  end

  validates :source_division_id, :sentence_number, :presence => true
  validates_with Proiel::SentenceAnnotationValidator

  # Language tag for the sentence
  delegate :language_tag, :to => :source_division

  # Language for the sentence
  delegate :language, :to => :source_division

  ordered_on :sentence_number, "source_division.sentences"

  # Returns a citation for the sentence.
  def citation
    [source_division.source.citation_part,
      citation_make_range(tokens.first.citation_part,
                          tokens.last.citation_part)].join(' ')
  end

  # All sentences within a window of +before_limit+ sentences before and
  # +after_limit+ sentences after the sentence within the source division in
  # the order of presentation.
  #
  # Options
  #
  # <tt>include_previous_source_division</tt>: include sentences from previous
  #      source divisions in the same source.
  #
  def sentence_window(before_limit = 5, after_limit = 5, options = {})
    # Grab the sentence IDs we want in separate statements because the
    # expressions are sensitive to ordering.
    s = previous_objects.order('sentence_number DESC').limit(before_limit).pluck(:id)

    if options[:include_previous_source_division] and !source_division.previous_object.nil? and s.count < before_limit
      s += source_division.previous_object.sentences.order('sentence_number DESC').limit(before_limit - s.count).pluck(:id)
    end

    s += next_objects.limit(after_limit).pluck(:id)
    s += [id]

    Sentence.joins(:source_division).order('source_divisions.position, sentence_number ASC').where(:id => s)
  end

  # Returns the parent object for the sentence, which will be its
  # source division.
  def parent
    source_division
  end

  def completion
    status # deprecated
  end

  # TODO: implement this better
  def status=(new_status, user_id = nil)
    case new_status.to_sym
    when :reviewed
      annotated_at, annotated_by = Time.now, user_id
      reviewed_at, reviewed_by = Time.now, user_id
    when :annotated
      annotated_at, annotated_by = Time.now, user_id
      reviewed_at, reviewed_by = nil, nil
    when :unannotated
      annotated_at, annotated_by = nil, nil
      reviewed_at, reviewed_by = nil, nil
    else
      raise ArgumentError, 'invalid status'
    end
  end

  # Returns the completion state.
  def status
    if is_reviewed?
      :reviewed
    elsif is_annotated?
      :annotated
    else
      :unannotated
    end
  end

  def syntactic_annotation=(dependency_graph)
    # This is a two step process: first figure out if any tokens have been added or
    # removed (this only applies to empty dependency tokens). Then update each token
    # in the sentence with new dependency information.
    #
    # Since by validation constraints all tokens in the sentence have to be annotated
    # if any single one is, we do not have to bother with partial annotations.

    # Work inside a transaction since we have lots of small pieces that must go together.
    Token.transaction do
      ts = tokens.takes_syntax

      removed_token_ids = ts.map(&:id) - dependency_graph.nodes.map(&:identifier)
      added_token_ids = dependency_graph.nodes.map(&:identifier) - ts.map(&:id)

      removed_tokens = ts.select { |token| removed_token_ids.include?(token.id) }

      # This list of "removed" tokens is actually not a list of tokens to be
      # deleted, but all the tokens not included in the dependency graph. We need
      # to make sure that only empty dependency nodes are actually deleted; if others
      # are present, the user has given us an incomplete analysis.
      raise "Incomplete dependency graph" unless removed_tokens.all?(&:is_empty?)

      removed_tokens.each { |token| token.destroy }

      # We will append new empty nodes at the end of the token sequence. Establish
      # which token_number to start at.
      @new_token_number ||= max_token_number + 1
      id_map = Hash[*tokens.map { |token| [token.id, token.id] }.flatten]

      dependency_graph.nodes.each do |node|
        unless id_map[node.identifier]
          raise "Unexpected new node" unless added_token_ids.include?(node.identifier)
          token = tokens.new
          token.token_number = @new_token_number
          token.empty_token_sort = node.data[:empty]
          token.save!
          id_map[node.identifier] = token.id
          @new_token_number += 1
        end
      end

      # Now we can iterate the sentence and update all tokens with new annotation
      # and secondary edges.
      dependency_graph.nodes.each do |node|
        token = tokens.find(id_map[node.identifier])
        token.head_id = id_map[node.head.identifier]
        token.relation_tag = node.relation

        # Slash edges are marked as dependent on the association level, so when we
        # destroyed empty tokens, the orphaned slashes should also have gone away.
        # The remaining slashes will however have to be updated "manually".
        token.slash_out_edges.each { |edge| edge.destroy }
        node.slashes_with_interpretations.each do |slashee, interpretation|
          SlashEdge.create!(:slasher_id => token.id,
                            :slashee_id => id_map[slashee.identifier],
                            :relation_tag => interpretation.to_s)
        end
        token.save!
      end
    end
  end

  def syntactic_annotation_with_tokens(overlaid_features = {})
    d = {}
    d[:tokens] = Hash[*tokens.takes_syntax.collect do |token|
      mh = token.morph_features ? token.morph_features.morphology_to_hash : {}

      [token.id, {
        # FIXME: refactor
        :morph_features => mh.merge({
          :language => language.tag,
          :finite => ['i', 's', 'm', 'o'].include?(mh[:mood]),
          :form => token.form,
          :lemma => token.lemma ? token.lemma.lemma : nil,
          :pos => token.morph_features ? token.morph_features.pos_s : nil,
        }),
        :empty => token.is_empty? ? token.empty_token_sort : false,
        :form => token.form,
        :token_number => token.token_number
      } ]
    end.flatten]

    d[:structure] = (overlaid_features and ActiveSupport::JSON.decode(overlaid_features)) || (has_dependency_annotation? ? dependency_graph.to_h : {})

    d[:relations] = RelationTag.all.select(&:primary)

    d
  end

  def morphological_annotation(overlaid_features = {})
    tokens.takes_morphology.map do |token|
      suggestions = token.guess_morphology!(overlaid_features["morph-features-#{token.id}".to_sym]) #FIXME

      [token, suggestions]
    end
  end

  # Returns the maximum token number in the sentence.
  def max_token_number
    self.tokens.maximum(:token_number)
  end

  # Returns the minimum token number in the sentence.
  def min_token_number
    self.tokens.minimum(:token_number)
  end

  # Tests if the next sentence can be appended to this sentence using
  # +append_next_sentence!+.
  def is_next_sentence_appendable?
    # There must be a next sentence, but there must be no sentence-level
    # presentation text intervening.
    has_next? and presentation_after.blank? and next_object.presentation_before.blank?
  end

  # Appends the next sentence onto this sentence and destroys the old
  # sentence. This also removes all dependency annotation from both
  # sentences to ensure validity.
  def append_next_sentence!
    raise ArgumentError unless is_next_sentence_appendable?

    Sentence.transaction do
      remove_syntax_and_info_structure!
      next_object.remove_syntax_and_info_structure!

      append_tokens!(next_object.tokens)

      # Move presentation_after from the next sentence to this one and destroy
      # the next sentence.
      self.presentation_after = next_object.presentation_after
      save!

      next_object.destroy
    end
  end

  # Creates a new token and appends it to the end of the sentence. The
  # function is equivalent to +create!+ except for the automatic
  # positioning of the new token in the sentence's linearization
  # sequence.
  def append_new_token!(attrs = {})
    tokens.create!(attrs.merge({ :token_number => max_token_number + 1 }))
  end

  # Tests if the sentence can be split at a given token. The given token
  # is assumed to be the first token of a new sentence if the original
  # sentence were split.
  def is_splitable?(t)
    raise ArgumentError unless tokens.include?(t)

    t2 = t.next_object

    not t.is_empty? and t.has_previous? and not t.previous_object.is_empty?
  end

  # Split the sentence into two successive sentences. The point to split
  # the sentence at is given by a token. The token will be the first token
  # of a new sentence.
  #
  #      Original sentence        Truncated sentence   New sentence
  #      t1 t2 t3 t4 t5      →        t1 t2 t3       |    t4 t5
  #               ^
  #           split here
  #
  # Single-token annotation is not altered. Multi-token annotation is
  # checked for validity. If valid, it is preserved to the extent possible.
  #
  # It is the callers responsibility to update any affected annotation
  # flags (i.e. reviewed/non-reviewed).
  #
  # The new sentence inherits the +assigned_to+ field from the current
  # sentence.

  def split_sentence!(split_token)
    raise ArgumentError unless tokens.include?(split_token)
    raise "sentence is invalid" unless valid? # this is necessary to avoid trouble with the invariant at the end

    Sentence.transaction do
      # Determine which tokens to keep in the new sentence: all non-empty
      # tokens up to but not incuding token and empty tokens that are direct
      # descendants of one of these.
      us, them = tokens.partition do |t|
        if t.is_empty? and t.head
          t.head.token_number < split_token.token_number
        else
          t.token_number < split_token.token_number
        end
      end

      # If a token has a head outside the set it belongs to, detach it so
      # that it becomes a root daughter and give it the relation PRED
      # unless it already has the relation VOC or PARPRED.
      [us, them].each do |s|
        s.each do |t|
          unless s.include?(t.head)
            t.head_id = nil
            t.relation = 'pred' if t.relation and !['voc', 'parpred'].include?(t.relation.tag)
            t.save!
          end
        end
      end

      # Construct new sentence by moving tokens from the old sentence,
      # inheriting assigned_to and taking over presentation_after from the
      # old sentence. Then ditch annotation unless result is invalid.
      new_sentence = insert_new_sentence! :assigned_to => assigned_to,
        :presentation_after => presentation_after

      them.each do |t|
        new_sentence.tokens << t
        t.save!
      end

      new_sentence.remove_syntax_and_info_structure! unless new_sentence.valid?

      # Update old sentence by clearing presentation_after and reloading
      # token association so that any cached tokens do not appear in both
      # old and new sentence associations. Then ditch annotation unless
      # result is valid.
      self.presentation_after = nil
      self.tokens.reload
      self.remove_syntax_and_info_structure! unless self.valid?

      # Now double-check that sentences are valid.
      raise "sentence is invalid after splitting" unless new_sentence.valid? and self.valid?
    end
  end

  private

  # Inserts a new sentence after the current sentence. Attributes to the
  # new sentence can be given in +attributes+ (except +sentence_number+,
  # which is automatically computed).
  def insert_new_sentence!(attributes = {})
    # FIXME: is this necessary? Find out in tests?
    new_sentence = nil

    Sentence.transaction do
      parent.sentences.find(:all, :conditions => ["sentence_number > ?", sentence_number]).sort do |x, y|
        y.sentence_number <=> x.sentence_number
      end.each do |s|
        s.sentence_number += 1
        s.save!
      end

      new_sentence = parent.sentences.create!(attributes.merge({ :sentence_number => sentence_number + 1 }))
    end

    new_sentence
  end

  protected

  # removes information about when and by whom the sentence was annotated
  def remove_annotation_metadata!
    self.annotated_by = nil
    self.annotated_at = nil
    self.reviewed_by = nil
    self.reviewed_at = nil
    save!
  end

  public

  # Deletes syntactic annotaton, information structure annotation and
  # annotation metadata from sentence and reloads token association.
  def remove_syntax_and_info_structure!
    self.tokens.each do |t|
      if t.is_empty?
        t.destroy
      else
        t.relation_tag = nil
        t.head_id = nil
        t.slash_out_edges.each { |sl| sl.destroy }
        t.information_status_tag = nil
        t.antecedent_id = nil
        t.save!
      end
    end
    tokens.reload
    remove_annotation_metadata!
  end

  private

  def append_tokens!(ts) #:nodoc:
    ts.each do |t|
      t.sentence_id = id
      t.token_number = (self.max_token_number || -1) + 1
      t.save!
    end
  end

  def prepend_tokens!(ts) #:nodoc:
    m = self.min_token_number

    if m.nil?
      # No tokens in the sentence? Curious, must be a new one.
    elsif m + 1 > ts.size
      # We're in luck, there are free token numbers left.
    else
      # Ye gods! We have to make room.
      self.tokens.sort { |x, y| y.token_number <=> x.token_number }.each do |t|
        t.token_number += ts.size
        t.save!
      end
    end

    i = 0

    ts.each_with_index do |t, i|
      t.sentence_id = id
      t.token_number = i
      t.save!
    end
  end

  public

  # Returns +true+ if sentence has been annotated.
  def is_annotated?
    !annotated_at.nil?
  end

  # Flags the sentence as annotated and saves the sentence.
  def set_annotated!(user)
    unless is_annotated?
      self.annotated_by = user.id
      self.annotated_at = Time.now
      save!
    end
  end

  # Returns +true+ if sentence has been reviewed.
  def is_reviewed?
    !reviewed_at.nil?
  end

  # Flags the sentence as reviewed and saves the sentence. If the sentence has
  # not already been annotated, it will be flagged as annotated as well.
  def set_reviewed!(user)
    unless is_reviewed?
      set_annotated!(user)

      self.reviewed_by = user.id
      self.reviewed_at = Time.now
      save!
    end
  end

  # "Unflags" the sentence as reviewed and saves the sentence.
  def unset_reviewed!(user)
    if is_reviewed?
      self.reviewed_by = nil
      self.reviewed_at = nil
      save!
    end
  end

  # Returns the dependency graph for the sentence.
  def dependency_graph
    PROIEL::DependencyGraph.new do |g|
      tokens.takes_syntax.each { |t| g.badd_node(t.id, t.relation_tag, t.head ? t.head.id : nil,
                                                           Hash[*t.slash_out_edges.map { |se| [se.slashee.id, se.relation_tag ] }.flatten],
                                                           { :empty => t.empty_token_sort || false,
                                                             :token_number => t.token_number,
                                                             :morph_features => t.morph_features,
                                                             :form => t.form }) }
    end
  end

  # Returns +true+ if sentence has dependency annotation.
  def has_dependency_annotation?
    tokens.takes_syntax.first && !tokens.takes_syntax.first.relation.nil?
  end

  # Returns +true+ if sentence has morphological annotation (i.e.
  # morphology + lemma).
  def has_morphological_annotation?
    # Assumed invariant: morphologically annotated sentence <=> all
    # morphology tokens have non-nil morphology and lemma_id attributes.
    tokens.takes_morphology.first && !tokens.takes_morphology.first.morphology.nil?
  end

  # Returns the root token in the dependency graph or +nil+ if none
  # exists.
  def root_dependency_token
    # TODO: add a validation rule that verifies that root_dependency_tokens only matches one
    # token?
    tokens.takes_syntax.dependency_root.first
  end

  def to_s
    [presentation_before, tokens.visible.all.map(&:to_s).join, presentation_after].compact.join
  end

  # Returns the maximum depth of the dependency graph, i.e. the maximum
  # distance from the root to a node in the graph in number of edges.
  def max_depth
    tokens.map(&:depth).max
  end

  # Returns all presentation text before the sentence (including presentation
  # text from the source division, if any). If there is no presentation text,
  # the function returns an empty string.
  def all_presentation_before
    p = []
    p << source_division.presentation_before unless has_previous?
    p << presentation_before
    p.join
  end

  # Returns all presentation text after the sentence (including presentation
  # text from the source division, if any). If there is no presentation text,
  # the function returns an empty string.
  def all_presentation_after
    p = []
    p << presentation_after
    p << source_division.presentation_after unless has_next?
    p.join
  end
end
