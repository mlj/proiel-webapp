# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
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

class Token < ActiveRecord::Base
  attr_accessible :sentence_id, :token_number, :form, :lemma_id, :head_id,
    :source_morphology_tag, :source_lemma, :foreign_ids, :information_status_tag,
    :empty_token_sort, :contrast_group, :token_alignment_id,
    :automatic_token_alignment, :dependency_alignment_id, :antecedent_id,
    :morphology_tag, :citation_part, :presentation_before, :presentation_after,
    :relation_tag, :created_at, :updated_at

  change_logging

  blankable_attributes :antecedent_id, :automatic_token_alignment,
    :contrast_group, :dependency_alignment_id, :empty_token_sort, :foreign_ids,
    :form, :head_id, :information_status_tag, :lemma_id, :morphology_tag,
    :presentation_after, :presentation_before, :relation_tag, :source_lemma,
    :source_morphology_tag, :token_alignment_id

  belongs_to :sentence
  belongs_to :lemma
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  belongs_to :head, :class_name => 'Token'
  has_many :dependents, :class_name => 'Token', :foreign_key => 'head_id'

  has_many :slash_out_edges, :class_name => 'SlashEdge', :foreign_key => 'slasher_id', :dependent => :destroy
  has_many :slash_in_edges, :class_name => 'SlashEdge', :foreign_key => 'slashee_id', :dependent => :destroy
  has_many :slashees, :through => :slash_out_edges
  has_many :slashers, :through => :slash_in_edges

  has_many :outgoing_semantic_relations, :class_name => 'SemanticRelation', :foreign_key => 'controller_id', :dependent => :destroy
  has_many :incoming_semantic_relations, :class_name => 'SemanticRelation', :foreign_key => 'target_id', :dependent => :destroy

  belongs_to :token_alignment, :class_name => 'Token', :foreign_key => 'token_alignment_id'
  belongs_to :dependency_alignment, :class_name => 'Token', :foreign_key => 'dependency_alignment_id'
  has_many :dependency_alignment_terminations

  has_many :anaphors, :class_name => 'Token', :foreign_key => 'antecedent_id', :dependent => :nullify
  belongs_to :antecedent, :class_name => 'Token', :foreign_key => 'antecedent_id'

  composed_of :morphology, :mapping => %w(morphology_tag to_s), :allow_nil => true, :converter => Proc.new { |x| Morphology.new(x) }

  # form must be on the appropriate Unicode normalization form
  validates_unicode_normalization_of :form, :form => UNICODE_NORMALIZATION_FORM

#  validates_tag_set_inclusion_of :source_morphology_tag, MorphologyTag, :allow_nil => true, :message => "%{value} is not a valid source morphology tag"
#  validates_tag_set_inclusion_of :morphology_tag, MorphologyTag, :allow_nil => true

  tag_attribute :information_status, :information_status_tag, InformationStatusTag, :allow_nil => true
  tag_attribute :relation, :relation_tag, RelationTag, :allow_nil => true
  delegate :part_of_speech, :to => :lemma, :allow_nil => true
  delegate :part_of_speech_tag, :to => :lemma, :allow_nil => true
  delegate :language, :to => :sentence
  delegate :language_tag, :to => :sentence
  delegate :source_citation_part, to: :sentence

  validates :sentence_id, :token_number, :presence => true
  validates_with Proiel::TokenAnnotationValidator

  ordered_on :token_number, "sentence.tokens"

  citation_on

  # A token with +citation_part+ set.
  def self.with_citation
    where("citation_part IS NOT NULL AND citation_part != ''")
  end

  # A visible token, i.e. is a non-empty token.
  def self.visible
    where(:empty_token_sort => nil)
  end

  # An invisible token, i.e. an empty token.
  def self.invisible
    where("empty_token_sort IS NOT NULL")
  end

  # A token that can be annotated with morphology.
  def self.takes_morphology
    visible
  end

  # A token that can be annotated with syntax (i.e. dependency relations).
  def self.takes_syntax
    where("empty_token_sort IS NULL OR empty_token_sort != 'P'")
  end

  # A token that is at the root of the dependency tree.
  def self.dependency_root
    where("head_id IS NULL")
  end

  # A token belonging to a sentence that has not been annotated.
  def self.unannotated
    joins(:sentence).where(:sentences => { :status_tag => 'unannotated' })
  end

  # A token belonging to a sentence that has been annotated.
  def self.annotated
    joins(:sentence).where(:sentences => { :status_tag => ['annotated', 'reviewed'] })
  end

  # A token belonging to a sentence that has not been reviewed.
  def self.unreviewed
    joins(:sentence).where(:sentences => { :status_tag => ['annotated', 'unannotated'] })
  end

  # A token belonging to a sentence that has been reviewed.
  def self.reviewed
    joins(:sentence).where(:sentences => { :status_tag => 'reviewed' })
  end

  # Returns the nearest anaphor or an empty array if there is none.
  def nearest_anaphor
    anaphors.min { |x, y| word_distance_between(x) <=> word_distance_between(y) }
  end

  # Returns the morphological features for the token or +nil+ if none
  # are set.
  def morph_features
    # We can rely on the invariant !lemma.blank? <=>
    # !morphology.blank?
    if lemma
      MorphFeatures.new(lemma, morphology)
    else
      nil
    end
  end

  # Sets the morphological features for the token. Executes a +save!+
  # on the token object, which will result in validation of all token
  # attributes. Will also create a new Lemma object if necessary.
  # Returns the morphological features. It is guaranteed that no
  # updating will take place if the morph-features are unchanged.
  def morph_features=(f)
    Token.transaction do
      if f.nil?
        self.morphology = nil
        self.lemma = nil
        self.save!
      elsif f.is_a?(String)
        s1, s2, s3, s4 = f.split(',')
        self.morph_features = MorphFeatures.new([s1, s2, s3].join(','), s4)
      elsif self.morphology != f.morphology or f.lemma.new_record? or f.lemma != self.lemma
        self.morphology = f.morphology
        f.lemma.save! if f.lemma.new_record?
        self.lemma = f.lemma
        self.save!
      end
    end

    f
  end

  # Returns the source morphological features for the token or nil if
  # none are set.
  def source_morph_features
    # Source morph-features may be incomplete, so if any of the
    # relevant fields are set we should return an object. We will have
    # to pass along the language, as the +source_lemma+ attribute is a
    # serialized lemma specification without language code.
    if source_lemma or source_morphology_tag
      MorphFeatures.new([source_lemma, language.tag].join(','), source_morphology_tag)
    else
      nil
    end
  end

  # Sets the source morphological features for the token. Executes a
  # +save!+ on the token object, which will result in validation of
  # all token attributes.  Returns the morphological features. It is
  # guaranteed that no updating will take place if the morph-features
  # are unchanged.
  def source_morph_features=(f)
    Token.transaction do
      if f.nil?
        self.source_morphology_tag = nil
        self.source_lemma = nil
        self.save!
      elsif f.is_a?(String)
        s1, s2, s3, s4 = f.split(',')
        self.source_morph_features = MorphFeatures.new([s1, s2, s3].join(','), s4)
      elsif self.source_morphology_tag != f.morphology or f.lemma_s != self.source_lemma
        self.source_morphology_tag = f.morphology
        self.source_lemma = f.lemma_s
        self.save!
      end
    end
  end

  MorphFeatures::POS_PREDICATES.keys.each do |k|
    next if k == :verb? or k == :conjunction?
    delegate k, :to => :morph_features, :allow_nil => true
  end

  MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.each do |k|
    delegate k, :to => :morph_features, :allow_nil => true
  end

  delegate :predicative?, :to => :relation, :allow_nil => true
  delegate :nominal?, :to => :relation, :allow_nil => true
  delegate :appositive?, :to => :relation, :allow_nil => true

  # Returns true if the token is a verb. If +include_empty_tokens+ is
  # true, also returns true for an empty node with its empty token
  # sort set to verb.
  def verb?(include_empty_tokens = true)
    (include_empty_tokens && empty_token_sort == 'V') || (morph_features and morph_features.verb?)
  end

  # Returns +true+ if the token is a conjunction. If +include_empty_tokens+
  # is true, also returns +true+ for an empty node with its empty token
  # sort set to conjunction, i.e. for asyndetic conjunctions.
  def conjunction?(include_empty_tokens = true)
    (include_empty_tokens && empty_token_sort == 'C') || (morph_features and morph_features.conjunction?)
  end

  def parent
    sentence
  end

  # Returns true if this is an empty token, i.e. a token used for empty nodes
  # in dependency structures.
  def is_empty?
    !empty_token_sort.nil?
  end

  # Returns true if this token is visible.
  def is_visible?
    empty_token_sort.nil?
  end

  alias :is_morphtaggable? :is_visible? # deprecated

  # Returns the dependency subgraph for the token as an unordered list.
  def subgraph_set
    [self] + dependents.map(&:subgraph_set).flatten
  end

  # Returns the dependency alignment subgraph for the token as an unordered
  # list.
  def dependency_alignment_subgraph_set(aligned_source)
    unless is_dependency_alignment_terminator?(aligned_source)
      [self] + dependents.map { |d| d.dependency_alignment_subgraph_set(aligned_source) }.flatten
    else
      []
    end
  end

  # Returns true if token is a terminator in dependency alignment.
  def is_dependency_alignment_terminator?(aligned_source)
    not dependency_alignment_terminations.count(:conditions => { :source_id => aligned_source.id }).zero?
  end

  # Returns the dependency alignment set that the token is a member of, i.e.
  # an unordered list of tokens that are members of two dependency aligned
  # subgraphs or an empty list if the token is unaligned. The total number
  # of edges traversed before an alignment was identified is also returned.
  # The results are returned as a pair consisting of the list and the
  # edge count.
  def dependency_alignment_set
    alignment = best_dependency_alignment

    if alignment
      primary, secondary, edge_count = alignment

      # Grab both subgraphs
      [primary.dependency_alignment_subgraph_set(secondary.sentence.source_division.source) +
       secondary.dependency_alignment_subgraph_set(primary.sentence.source_division.source), edge_count]
    else
      # No best dependency alignment.
      [[], 0]
    end
  end

  # Returns the best dependency alignment available. If none exists, the
  # sentence alignment is returned. The alignment is returned as a triple
  # of token IDs and the number of edges traversed before an alignment
  # was found, or if none exists, +nil+.
  def best_dependency_alignment
    aligned_source = sentence.source_division.aligned_source_division.source

    # Traverse the tree up until we find a dependency alignment edge or
    # the root node.
    t = self
    edge_count = 0

    while t and not t.dependency_alignment
      # If we've found a terminator we abort here.
      return nil if t.is_dependency_alignment_terminator?(aligned_source)

      t = t.head
      edge_count += 1
    end

    if t and t.dependency_alignment
      [t, t.dependency_alignment, edge_count]
    elsif sentence.sentence_alignment
      [sentence.root_dependency_token, sentence.sentence_alignment.root_dependency_token, edge_count]
    else
      nil
    end
  end

  UNANNOTATABLE_PARTS_OF_SPEECH = /^(C-|R-|P[rd])$/ # conjunctions, prepositions, relative pronouns and demonstrative pronouns

  # Returns true if the token has a nominal POS or a nominal syntactic relation,
  # or if one of its dependents is an article.
  def is_annotatable?
    information_status_tag == 'no_info_status' || # manually marked as annotatable
      (information_status_tag != 'info_unannotatable' && \
       (noun? || pronoun? || nominal? || dependents.any?(&:article?)) &&
       (part_of_speech_tag.nil? || !part_of_speech_tag[UNANNOTATABLE_PARTS_OF_SPEECH]) &&
       !predicative? && !appositive?)
  end

  def self.tokens_in_same_source?(t1, t2)
    t1.sentence.source_division.source == t2.sentence.source_division.source
  end

  def self.tokens_in_contiguous_source_divisions?(t1, t2)
    t1.sentence.source_division.source.source_divisions.count(:all, :conditions => ['position between ? and ?', t1.sentence.source_division.position, t2.sentence.source_division.position]) < 3
  end

  # True if the token +t+ belongs to the same sentence as this token.
  def belongs_to_same_sentence?(t)
    sentence == t.sentence
  end

  # True if the token +t+ belongs to the same source division as this token.
  def belongs_to_same_source_division?(t)
    sentence.source_division == t.sentence.source_division
  end

  # Returns the distance between this token and the token +t+ measured in
  # number of sentences.
  def sentence_distance_between(t)
    if belongs_to_same_source_division?(t)
      i = [sentence.sentence_number, t.sentence.sentence_number].sort
      sentence.source_division.sentences.where('sentence_number >= ? AND sentence_number < ?', *i).count
    else
      raise ArgumentError, "token does not belong to the same source division"
    end
  end

  # Returns the distance between this token and another token measured in
  # number of words.
  def word_distance_between(t)
    x = self
    y = t

    x = x.head if x.empty_token_sort == 'P'
    y = y.head if y.empty_token_sort == 'P'

    if x.belongs_to_same_sentence?(y)
      i = [x.token_number, y.token_number].sort

      sentence.tokens.visible.where('token_number >= ? AND token_number < ?', *i).count
    elsif x.belongs_to_same_source_division?(y)
      x, y = y, x if x.sentence.sentence_number > y.sentence.sentence_number

      x.sentence.tokens.visible.where('token_number >= ?', x.token_number).count +
        y.sentence.tokens.visible.where('token_number < ?', y.token_number).count +
        Token.where(:sentence_id => x.sentence.source_division.sentences.where('sentence_number > ? AND sentence_number < ?', x.sentence.sentence_number, y.sentence.sentence_number)).visible.count
    else
      raise ArgumentError, "token does not belong to the same source division"
    end
  end

  def to_s(options = {})
    token_text = if [*options[:highlight_tokens]].include?(self.id)
                   "*#{form}*"
                 else
                   form
                 end

    [presentation_before, token_text, presentation_after].compact.join
  end

  def self.presentation_form
    pluck("CONCAT(IFNULL(presentation_before, ''), form, IFNULL(presentation_after, ''))")
  end

  def sentence_context_to_s
    [previous_objects.order(:token_number).presentation_form.join + (presentation_before || ''), form, (presentation_after || '') + next_objects.order(:token_number).presentation_form.join]
  end

  # Tests if token can be joined with the following token.
  #
  # The token and its following token are joinable if
  #   1. both tokens are non-empty,
  #   2. intervening presentation data is empty or whitespace only, and
  #   3. both tokens have the same citation data.

  def is_joinable?
    t2 = next_object
    not is_empty? and t2 and not t2.is_empty? and
      (presentation_after.nil? or presentation_after[/^\s*$/]) and
      (t2.presentation_before.nil? or t2.presentation_before[/^\s*$/]) and
      (t2.citation_part == citation_part)
  end

  # Joins the token with the token following it in the linearisation of
  # tokens within the sentence. The succeeding token is destroyed, and the
  # original token's word form is updated. All other data is left
  # unchanged.
  #
  # The function returns the joined token.

  def join_with_next_token!
    raise ArgumentError unless is_joinable?

    t2 = self.next_object

    Sentence.transaction do
      sentence.remove_syntax_and_info_structure!

      self.form = [self.form, self.presentation_after,
        t2.presentation_before, t2.form].compact.join
      self.presentation_after = t2.presentation_after
      self.save!

      t2.destroy
    end

    self
  end

  # Tests if token can be split.
  #
  # The token can be split if
  #   1. it is non-empty and
  #   2. it's <tt>form</tt> is non-empty.

  def is_splitable?
    not is_empty? and PROIEL::Tokenization.is_splitable?(form)
  end

  def split_token!
    components = PROIEL::Tokenization.split_form(language_tag, form)

    old_surface = form
    new_surface = components.join
    empty_forms = components.each_with_index.any? { |t, i| i.even? and t.empty? }

    raise ArgumentError, 'invalid number of components' unless components.length.odd?
    raise ArgumentError, 'invalid empty token form' if empty_forms
    raise ArgumentError, 'old and new surface forms do not match' unless old_surface == new_surface

    if components.length > 1
      # Add the original presentation_after value to the components array. Now
      # components contains a sequence of form and presentation_after values
      # that can be iterated in pairs. Duplicate the array to avoid interfering
      # with the callers copy.
      ts = components + [presentation_after]

      Sentence.transaction do
        sentence.remove_syntax_and_info_structure!

        ts.each_slice(2).inject(nil) do |current_token, (new_form, new_presentation_after)|
          if current_token.nil?
            # First time around we update ourself and return ourself
            update_attributes! form: new_form,
              presentation_after: new_presentation_after

            self
          else
            # Insert a new token and return it
            current_token.insert_new_token! form: new_form,
              presentation_after: new_presentation_after,
              citation_part: citation_part
          end
        end
      end
    end
  end

  # Inserts a new token after the current token. Attributes to the
  # new token can be given in +attributes+ (except +token_number+,
  # which is automatically computed).
  #
  # The function returns the new token.
  def insert_new_token!(attributes = {})
    new_token = nil

    Token.transaction do
      parent.tokens.find(:all, :conditions => ["token_number > ?", token_number]).sort do |x, y|
        y.token_number <=> x.token_number
      end.each do |s|
        s.token_number += 1
        s.save!
      end

      new_token = parent.tokens.create!(attributes.merge({ :token_number => token_number + 1 }))
    end

    new_token
  end

  # Guesses morphological features using the morphological tools that have
  # been for the language in question. Any morphological features already
  # set for the token will take precedence, as will any value of the
  # +source_morph_features+ attribute. If features can be guessed, these
  # are set for the token, but the token is not saved. The function returns
  # a list of alternative suggestions in order of decreasing probability.
  # To check if the guesser altered the features of the token, check the
  # value of +changed?+.
  def guess_morphology!(overlaid_features = nil)
    # Guess morphology using both +morph_features+ and
    # +source_morph_features+. The only way of making use of
    # +source_morph_features+ is to include them here as there is no
    # guarantee that these will be complete, so we may have to use the
    # guesser to complete them. The motivation for also filtering the
    # guesses using +morph_features+ is so that we can supply a
    # 'reasonable' set of alternative suggestions (for example of
    # alternative lemmata) along for a token with +morph_features+ already
    # set.
    _, pick, *suggestions = language.guess_morphology(form, morph_features || source_morph_features)

    # Figure out which features to use. The following is the sequence of
    # priority: 1) Any value set by the caller, 2) any value already set on
    # the token. +source_morphology_tag+ only has an effect on the guessing of
    # morphology.
    new_morph_features = if overlaid_features
                           # FIXME
                           x, y, z, w = overlaid_features.split(',')
                           MorphFeatures.new([x, y, z].join(','), w)
                         elsif morph_features
                           morph_features
                         elsif pick
                           pick
                         else
                           nil
                         end

    # FIXME: find a way of unifying this with morph_features=() ideally by
    # avoiding the implicit saving of objects.
    if new_morph_features
      self.morphology = new_morph_features.morphology
      self.lemma = new_morph_features.lemma
    else
      self.morphology = nil
      self.lemma = nil
    end

    # Return all suggestions but strip off the probabilities.
    suggestions.map(&:first)
  end

  def sem_tags_to_hash
    res = {}
    sem_tags = semantic_tags
    sem_tags += lemma.semantic_tags.reject { |tag| sem_tags.map(&:semantic_attribute).include?(tag.semantic_attribute) } if lemma
    sem_tags.each do |st|
      res[st.semantic_attribute.tag] = st.semantic_attribute_value.tag
    end
    res
  end

  # Returns the depth of the node, i.e. the distance from the root in number of edges.
  def depth
    if head
      head.depth + 1
    else
      0
    end
  end

  # Find ancestor among the primary relations of the dependency graph.
  def find_dependency_ancestor(&block)
    if head
      if block.call(head)
        head
      else
        head.find_dependency_ancestor(&block)
      end
    else
      nil
    end
  end

  # Iterate ancestors among the primary relations of the dependency graph.
  def each_dependency_ancestor(&block)
    if head
      block.call
      head.each_dependency_ancestor(&block)
    end
  end

  def find_semantic_relation_head(srt)
    if has_outgoing_relation_type?(srt)
      self
    elsif head
      head.find_semantic_relation_head(srt)
    else
      nil
    end
  end


  def semantic_relation_span(srt)
    raise "Token #{id} has no semantic relation of type #{srt.tag}" unless has_relation_type?(srt)
    sr_span(srt).flatten.sort { |x,y| x.token_number <=> y.token_number }
  end

  def label_semantic_relation_span(srt, slice = 5)
    res = []
    span = semantic_relation_span(srt)
    span.reject(&:is_empty?).each_with_index do |tk, i|
      res << tk.form
      res << "..." if tk.next_object and (i + 1) < span.size and span[i + 1] != tk.next_object
    end
    id.to_s + '\n' + sentence.citation + '\n' + res.each_slice(slice).to_a.map { |i| i.join(' ') }.join('\n')
  end

  protected

  def sr_span(srt)
    ([self] + dependents.reject do |d|
       d.is_empty? or d.has_relation_type?(srt)
     end.map do |dd|
       dd.sr_span(srt)
     end).flatten
  end

  public

  def has_relation_type?(srt)
    has_incoming_relation_type?(srt) or has_outgoing_relation_type?(srt)
  end

  def has_incoming_relation_type?(srt)
    incoming_semantic_relations.any? { |sr| sr.semantic_relation_type == srt }
  end

  def has_outgoing_relation_type?(srt)
    outgoing_semantic_relations.any? { |sr| sr.semantic_relation_type == srt }
  end

  delegate :is_reviewed?, :to => :sentence
  delegate :is_annotated?, :to => :sentence
  delegate :status, :to => :sentence
  delegate :status_tag, :to => :sentence

  presentation_on 'sentence', 'first_visible?', 'last_visible?'

  # Tests if the token is the first non-empty token in its sentence.
  def first_visible?
    not previous_objects.where('empty_token_sort IS NULL').exists?
  end

  # Tests if the token is the last non-empty token in its sentence.
  def last_visible?
    not next_objects.where('empty_token_sort IS NULL').exists?
  end

  # Returns the token form, if there is one, or generates a form on the format
  # "PRO-RELATION" if the token is a PRO token.
  def form_or_pro
    empty_token_sort == 'P' ? "PRO-#{relation.tag.upcase}" : form
  end
end
