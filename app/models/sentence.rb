#--
#
# Copyright 2007-2016 University of Oslo
# Copyright 2007-2016 Marius L. Jøhndal
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
    :source_division_id, :assigned_to, :presentation_before, :presentation_after,
    :status_tag, :created_at, :updated_at

  change_logging

  blankable_attributes :annotated_at, :annotated_by, :assigned_to,
    :automatic_alignment, :presentation_after, :presentation_before,
    :reviewed_at, :reviewed_by, :sentence_alignment_id

  belongs_to :source_division
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  belongs_to :annotator, :class_name => 'User', :foreign_key => 'annotated_by'
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewed_by'
  belongs_to :assignee, :class_name => 'User', :foreign_key => 'assigned_to'

  belongs_to :sentence_alignment, :class_name => 'Sentence', :foreign_key => 'sentence_alignment_id'

  has_many :tokens, :dependent => :destroy

  tag_attribute :status, :status_tag, StatusTag, :allow_nil => false

  # All tokens with dependents and information structure included
  def tokens_with_deps_and_is
    ts = tokens.includes(:dependents, :antecedent, :lemma, :slash_out_edges)
    prodrops, others = ts.partition { |token| token.empty_token_sort == 'P' }

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

      others.insert(insertion_point, prodrop)
    end

    others
  end

  # A sentence that has not been annotated.
  def self.unannotated
    where(:status_tag => 'unannotated')
  end

  # A sentence that has been annotated.
  def self.annotated
    where(:status_tag => ['annotated', 'reviewed'])
  end

  # A sentence that has not been reviewed.
  def self.unreviewed
    where(:status_tag => ['annotated', 'unannotated'])
  end

  # A sentence that has been reviewed.
  def self.reviewed
    where(:status_tag => 'reviewed')
  end

  # A sentence that belongs to a source.
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

  citation_on

  delegate :source_citation_part, to: :source_division

  def tokens_with_citation
    tokens.with_citation
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

  # Updates annotation for the sentence.
  #
  # Returns an array of new tokens.
  def update_annotation!(updated_tokens)
    Sentence.transaction do
      # Make a mapping from IDs to Token objects for existing tokens. We'll use
      # this to match Token objects with data in updated_tokens, and we'll
      # delete each Token object from the mapping as we update it so that we
      # can determine at the end if there are leftover Token objects that
      # haven't been updated.
      id_map = tokens.map { |t| [t.id.to_s, t] }.to_h

      slash_id_map = {}

      # We will append new empty nodes at the end of the token sequence.
      # Establish which token_number to start at.
      @new_token_number ||= max_token_number + 1

      # Create new tokens and add them to id_map. We have to create all new
      # tokens before doing any updating in case a head or slash relation
      # targets a new token.
      updated_tokens.each do |u|
        id = u['id']

        unless id_map.key?(id)
          raise ArgumentError unless id[/^new/]
          raise ArgumentError if u['empty_token_sort'].blank?

          t = tokens.new
          t.empty_token_sort = u['empty_token_sort']
          t.token_number = @new_token_number
          t.save!

          id_map[id] = t

          @new_token_number += 1
        else
          raise ArgumentError unless u['id'].to_i.to_s == u['id']
        end
      end

      updated_tokens.each do |u|
        id = u['id']

        raise unless id_map.key?(id)

        t = id_map[id]

        t.morphology = Morphology.new(u['msd'])

        # FIXME: disallow this by separating out lemma creation and dictionary
        lemma_pos = u['lemma']['part_of_speech_tag']
        lemma_base, lemma_variant = u['lemma']['form'].split('#')
        t.lemma = Lemma.find_by_part_of_speech_tag_and_lemma_and_variant_and_language(lemma_pos, lemma_base, lemma_variant, language_tag)

        unless lemma
          t.lemma = Lemma.create!(part_of_speech_tag: lemma_pos, lemma: lemma_base, variant: lemma_variant, language_tag: language_tag)
        end

        t.relation_tag = u['relation']
        t.head_id = id_map[u['head_id']]
        t.save!
      end

      # Pass 3: Remove old slashes and add new ones. Do this separately because we need relations to be in place for interpreted relations.
      updated_tokens.each do |u|
        id = u['id']

        t = id_map.remove(id)

        t.slash_out_edges.each { |edge| edge.destroy }

        t.slashes.each do |s|
          raise ArgumentError, "invalid slashee" if s.blank?

          interpretation =
            if t.is_empty? and
              (t.empty_token_sort == 'V' or t.relation_tag == 'pred') and
              (s.empty_token_sort == 'V' or s.relation_tag == 'pred') and
              t.relation_tag == slashee.relation_tag
              'pid'
            elsif t.relation_tag == 'xadv' or t.relation_tag == 'xobj'
              'xsub'
            else
              raise ArgumentError, "slashee has no relation" if slashee.relation_tag.blank?
              slashee.relation_tag
            end

          SlashEdge.create!(slasher_id: t.id,
                            slashee_id: id_map[slashee],
                            relation_tag: interpretation)
        end
      end

      id_map.each do |id, t|
        # Token is not in the data the caller gave us. If the token we have
        # in the database is an empty one, we can safely get rid of it. If it
        # is non-empty, the caller has made a mistake and given us an
        # incomplete token list.
        #
        # FIXME: At this point we ought to check that the token we're deleted
        # is not the head of any other token.
        #
        # Slash edges are marked as dependent on the association level so when we
        # destroy empty tokens, the orphaned slashes will also gone away.
        #
        # FIXME: We need to make sure that no other object in the database
        # points to this token.
        if t.is_empty?
          t.destroy
        else
          raise ArgumentError, "tokens missing from token list"
        end
      end
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
      # old sentence. Then ditch annotation unless result is valid.
      new_sentence = insert_new_sentence! :assigned_to => assigned_to,
        :presentation_after => presentation_after

      them.each do |t|
        new_sentence.tokens << t
        t.save!
      end

      # Inherit the annotation metadata so the validation works properly
      new_sentence.annotated_by = annotated_by
      new_sentence.annotated_at = annotated_at
      new_sentence.reviewed_by = reviewed_by
      new_sentence.reviewed_at = reviewed_at
      new_sentence.status_tag = status_tag
      
      # Ditch the annotation if the sentence is invalid.
      new_sentence.remove_syntax_and_info_structure!   unless new_sentence.valid?

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
      next_objects.order("sentence_number DESC").each do |s|
        s.sentence_number += 1
        s.save!
      end

      new_sentence = parent.sentences.create!(attributes.merge({ :sentence_number => sentence_number + 1, :status_tag => 'unannotated' }))
    end

    new_sentence
  end

  public

  # Deletes syntactic annotaton, information structure annotation and
  # annotation metadata from sentence and reloads token association.
  def remove_syntax_and_info_structure!
    update_attributes! status_tag: 'unannotated',
      annotated_by: nil, annotated_at: nil,
      reviewed_by: nil, reviewed_at: nil

    tokens.each do |t|
      t.slash_out_edges.each { |sl| sl.destroy }
      t.destroy if t.is_empty?
    end

    tokens.update_all :relation_tag => nil, :head_id => nil,
      :information_status_tag => nil, :antecedent_id => nil

    tokens.reload
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

    ts.each_with_index do |t, i|
      t.sentence_id = id
      t.token_number = i
      t.save!
    end
  end

  public

  # Returns true if sentence has been annotated.
  def is_annotated?
    status_tag == 'annotated' or status_tag == 'reviewed'
  end

  # Flags the sentence as annotated and saves the sentence.
  def set_annotated!(user)
    unless is_annotated?
      update_attributes! status_tag: 'annotated',
        annotated_by: (annotated_by || user.id), annotated_at: (annotated_at || Time.new)
    end
  end

  # Returns true if sentence has been reviewed.
  def is_reviewed?
    status_tag == 'reviewed'
  end

  # Flags the sentence as reviewed and saves the sentence.
  def set_reviewed!(user)
    unless is_reviewed?
      update_attributes! status_tag: 'reviewed',
        annotated_by: (annotated_by || user.id), annotated_at: (annotated_at || Time.new),
        reviewed_by: (reviewed_by || user.id), reviewed_at: (reviewed_at || Time.now)
    end
  end

  # Flags the sentence as not reviewed and saves the sentence.
  def unset_reviewed!(user)
    if is_reviewed?
      update_attributes! status_tag: 'annotated',
        reviewed_by: nil, reviewed_at: nil
    end
  end

  # Returns the dependency graph for the sentence.
  def dependency_graph
    Proiel::DependencyGraph.new do |g|
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

  def to_s(options = {})
    tokens_text = tokens.visible.map { |t| t.to_s(options) }.join
    [presentation_before, tokens_text, presentation_after].compact.join
  end

  # Returns the maximum depth of the dependency graph, i.e. the maximum
  # distance from the root to a node in the graph in number of edges.
  def max_depth
    tokens.map(&:depth).max
  end

  presentation_on 'source_division'

  # Returns the alignment source if any descendant object is aligned to an object in another source.
  #
  # This does not verify that all descendants with alignments actually refer to the
  # same source.
  def inferred_aligned_source
    if sentence_alignment_id.nil?
      tokens.each do |t|
        i = t.inferred_aligned_source
        return i unless i.nil?
      end

      nil
    else
      sentence_alignment.source
    end
  end

  def visualize(format, mode = :unsorted)
    mode = mode.to_sym
    visualizer = GraphvizVisualizer.instance

    case format
    when :svg
      visualizer.generate(self, format: :svg, mode: mode, fontname: 'Legendum')
    when :dot
      visualizer.generate(self, format: :dot, mode: mode)
    else
      raise ArgumentError, 'invalid format'
    end
  end
end
