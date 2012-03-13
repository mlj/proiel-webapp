#--
#
# Copyright 2007, 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
  belongs_to :source_division
  has_many :bookmarks
  has_many :notes, :as => :notable, :dependent => :destroy
  has_many :semantic_tags, :as => :taggable, :dependent => :destroy

  belongs_to :annotator, :class_name => 'User', :foreign_key => 'annotated_by'
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewed_by'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to'

  belongs_to :sentence_alignment, :class_name => 'Sentence', :foreign_key => 'sentence_alignment_id'

  # All tokens
  has_many :tokens, :order => 'token_number', :dependent => :destroy

  # All tokens with dependents and information structure included
  has_many :tokens_with_dependents_and_info_structure, :class_name => 'Token',
     :include => [:dependents, :antecedent], :order => 'tokens.token_number' do

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

  # Sentences that have not been annotated.
  named_scope :unannotated, :conditions => ["annotated_by IS NULL"]

  # Sentences that have been annotated.
  named_scope :annotated, :conditions => ["annotated_by IS NOT NULL"]

  # Sentences that have not been reviewed.
  named_scope :unreviewed, :conditions => ["reviewed_by IS NULL"]

  # Sentences that have been reviewed.
  named_scope :reviewed, :conditions => ["reviewed_by IS NOT NULL"]

  # Sentences that belong to source +source+.
  named_scope :by_source, lambda { |source|
    { :conditions => { :source_division_id => source.source_divisions.map(&:id) } }
  }

  # Sentences that have been black-listed in sentence alignment.
  named_scope :unalignable, :conditions => { "unalignable" => true }

  # General schema-defined validations
  validates_presence_of :source_division_id
  validates_presence_of :sentence_number

  validate :check_invariants

  acts_as_audited :except => [:annotated_by, :annotated_at, :reviewed_by, :reviewed_at]

  # Returns the language for the sentence.
  def language
    source_division.language
  end

  # Returns a citation for the sentence.
  def citation
    [source_division.source.citation_part,
      citation_make_range(tokens.first.citation_part,
                          tokens.last.citation_part)].join(' ')
  end

  #FIXME:DRY generalise < token

  # Deprecated
  def previous_sentences(include_previous_sd = false)
    ps = source_division.sentences.find(:all,
                                   :conditions => [ "sentence_number < ?", sentence_number ],
                                   :order => "sentence_number ASC")
    ps = source_division.previous.sentences.find(:all, :order => "sentence_number ASC" ) + ps if include_previous_sd and source_division.previous
    ps
  end

  def prev_sentences(limit = nil)
    options = {
      :conditions => ["sentence_number < ?", sentence_number],
      :order => "sentence_number DESC"
    }
    options[:limit] = limit if limit
    source_division.sentences.find(:all, options).reverse
  end

  def next_sentences(limit = nil)
    options = {
      :conditions => ["sentence_number > ?", sentence_number],
      :order => "sentence_number ASC"
    }
    options[:limit] = limit if limit

    source_division.sentences.find(:all, options)
  end

  # Returns the previous sentence in the linearisation sequence. Returns +nil+
  # if there is no previous sentence.
  def previous_sentence
    source_division.sentences.find(:first,
                                   :conditions => [ "sentence_number < ?", sentence_number ],
                                   :order => "sentence_number DESC")
  end

  # Returns the next sentence in the linearisation sequence. Returns +nil+
  # if there is no next sentence.
  def next_sentence
    source_division.sentences.find(:first,
                                   :conditions => [ "sentence_number > ?", sentence_number ],
                                   :order => "sentence_number ASC")
  end

  alias :next :next_sentence
  alias :previous :previous_sentence

  include Ordering

  def ordering_attribute
    :sentence_number
  end

  def ordering_collection
    source_division.sentences
  end

  # FIXME: backwards compatibility
  alias :has_next_sentence? :has_next?
  alias :has_previous_sentence? :has_previous?

  # Returns the parent object for the sentence, which will be its
  # source division.
  def parent
    source_division
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
      ts = tokens.dependency_annotatable

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
        token.relation = node.relation

        # Slash edges are marked as dependent on the association level, so when we
        # destroyed empty tokens, the orphaned slashes should also have gone away.
        # The remaining slashes will however have to be updated "manually".
        token.slash_out_edges.each { |edge| edge.destroy }
        node.slashes_with_interpretations.each do |slashee, interpretation|
          SlashEdge.create!(:slasher => token,
                            :slashee_id => id_map[slashee.identifier],
                            :relation => Relation.find_by_tag(interpretation.to_s))
        end
        token.save!
      end
    end
  end

  def syntactic_annotation_with_tokens(overlaid_features = {})
    d = {}
    d[:tokens] = Hash[*tokens.dependency_annotatable.collect do |token|
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

    d[:relations] = Relation.primary

    d
  end

  def morphological_annotation(overlaid_features = {})
    tokens.morphology_annotatable.map do |token|
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

  def is_next_sentence_appendable?
    has_next? and presentation_after.nil? and next_sentence.presentation_before.nil?
  end

  # Appends the next sentence onto this sentence and destroys the old
  # sentence. This also removes all dependency annotation from both
  # sentences to ensure validity.
  def append_next_sentence!
    raise ArgumentError unless is_next_sentence_appendable?

    Sentence.transaction do
      remove_syntax_and_info_structure!
      next_sentence.remove_syntax_and_info_structure!

      # Ensure that there is at least a single space after any punctuation
      # at the end of the sentence
      last_token = tokens.last

      if last_token
        last_token.presentation_after =
          (last_token.presentation_after || '').sub(/\s*$/, ' ')
        last_token.save!
      end

      append_tokens!(next_sentence.tokens)

      next_sentence.destroy
    end
  end

  # Creates a new token and appends it to the end of the sentence. The
  # function is equivalent to +create!+ except for the automatic
  # positioning of the new token in the sentence's linearization
  # sequence.
  def append_new_token!(attrs = {})
    tokens.create!(attrs.merge({ :token_number => max_token_number + 1 }))
  end

  def is_splitable_after?(t)
    raise ArgumentError unless tokens.include?(t)

    t2 = t.next_token

    t2 and not t2.is_empty?
  end

  # Split the sentence into two successive sentences. The point to split
  # the sentence at is given by a token. The token will be the first token
  # of a new sentence.
  #
  # Single-token annotation is not altered. Multi-token annotation is
  # checked for validity. If valid, it is preserved to the extent possible.
  #
  # It is the callers responsibility to update any affected annotation
  # flags (i.e. reviewed/non-reviewed).
  #
  # The new sentence inherits the +assigned_to+ field from the current
  # sentence.
  #
  # TODO: update all callers with remove_annotation_metadata!
  def split_sentence!(split_token)
    raise ArgumentError unless tokens.include?(split_token)
    raise "sentence is invalid" unless valid? # this is necessary to avoid trouble with the invariant at the end

    Sentence.transaction do
      new_sentence = insert_new_sentence! :assigned_to => assigned_to, :presentation_after => presentation_after
      self.presentation_after = nil

      self.tokens.reload

      # Determine which tokens to put in the new sentence: all non-empty
      # after and including +token+ and empty tokens that are direct
      # descendants of one of these.
      us, them = tokens.partition do |t|
        if t.is_empty? and t.head
          t.head.token_number < split_token.token_number
        else
          t.token_number < split_token.token_number
        end
      end

      them.each do |t|
        new_sentence.tokens << t
        t.save! # FIXME: is it already saved?
      end

      # Check multi-token annotation in both sentences. Start with the new
      # one. If a token has a head outside the sentence, detach it (so that
      # it becomes a root daughter instead) and give it the relation PRED
      # unless it already has the relation VOC or PARPRED.
      [new_sentence, self].each do |s|
        s.tokens.each do |t|
          unless s.tokens.include?(t.head)
            t.head_id = nil
            t.relation = 'pred' if t.relation and !['voc', 'parpred'].include?(t.relation.tag)
            t.save!
          end
        end

        # Check if both sentences are still valid. If not, we remove
        # annotation.
        s.remove_syntax_and_info_structure! unless s.valid?
      end

      # Check invariant
      raise "sentence is invalid after splitting" unless new_sentence.valid? and valid?
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

  # Deletes all syntactic and information structural annotation from
  # the sentence and reloads the tokens
  def remove_syntax_and_info_structure!
    self.tokens.each do |t|
      if t.is_empty?
        t.destroy
      else
        t.relation_id = nil
        t.head_id = nil
        t.slash_out_edges.each { |sl| sl.destroy }
        t.info_status = nil
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
      t.token_number = self.max_token_number + 1
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
      tokens.dependency_annotatable.each { |t| g.badd_node(t.id, t.relation.tag, t.head ? t.head.id : nil,
                                                           Hash[*t.slash_out_edges.map { |se| [se.slashee.id, se.relation.tag ] }.flatten],
                                                           { :empty => t.empty_token_sort || false,
                                                             :token_number => t.token_number,
                                                             :morph_features => t.morph_features,
                                                             :form => t.form }) }
    end
  end

  # Returns +true+ if sentence has dependency annotation.
  def has_dependency_annotation?
    tokens.dependency_annotatable.first && !tokens.dependency_annotatable.first.relation.nil?
  end

  # Returns +true+ if sentence has morphological annotation (i.e.
  # morphology + lemma).
  def has_morphological_annotation?
    # Assumed invariant: morphologically annotated sentence <=> all
    # morphology tokens have non-nil morphology and lemma_id attributes.
    tokens.morphology_annotatable.first && !tokens.morphology_annotatable.first.morphology.nil?
  end

  # Returns the root token in the dependency graph or +nil+ if none
  # exists.
  def root_dependency_token
    # TODO: add a validation rule that verifies that root_dependency_tokens only matches one
    # token?
    tokens.dependency_annotatable.root_dependency_tokens.first
  end

  protected

  def self.search(query, options = {})
    paginate options
  end

  private

  def check_invariants
    # FIXME? This breaks creation of new sentences
    # # Constraint: sentence must have at least one token.
    # if tokens.length < 1
    #   errors.add_to_base("Sentence must have at least one token")
    # end

    # Pairwise attributes: reviewed_by && reviewed_at
    # Pairwise attributes: annotated_by && annotated_at

    #   is_reviewed? <=> reviewed_by    sentence is reviewed
    #   is_annotated? <=> annotated_by  sentence is annotated
    #   has_dependency_annotation       sentence is dependency annotated

    # Invariant: sentence is reviewed => sentence is annotated
    if is_reviewed? and not is_annotated?
      errors.add_to_base("Reviewed sentence must be annotated")
    end

    # Invariant: sentence is annotated => sentence is dependency annotated
    if is_annotated? and not has_dependency_annotation?
      errors.add_to_base("Annotated sentence must have dependency annotation")
    end

    # Invariant: sentence is dependency annotated <=>
    # all dependency tokens have non-nil relation attributes <=> there exists one
    # dependency token with non-nil relation.
    if tokens.dependency_annotatable.any?(&:relation) and not tokens.dependency_annotatable.all?(&:relation)
      errors.add_to_base("Dependency annotation must be complete")
    end

    tokens.dependency_annotatable.each do |t|
      t.slash_out_edges.each do |se|
        add_dependency_error("Unconnected slash edge", [t]) if se.slashee.nil?
        add_dependency_error("Unlabeled slash edge", [t]) if se.relation.nil?
      end
    end

    # Check each token for validity (this could of course also be done with validates_associated),
    # but that leads to confusing error messages for users.
    tokens.each do |t|
      unless t.valid?
        t.errors.each_full { |msg| add_dependency_error(msg, [t]) }
      end
    end

    # Invariant: sentence is dependency annotated => dependency graph is valid
    if has_dependency_annotation?
      dependency_graph.valid?(lambda { |token_ids, msg| add_dependency_error(msg, Token.find(token_ids)) })
    end
  end

  def add_dependency_error(msg, tokens)
    ids = tokens.collect(&:token_number)
    errors.add_to_base("Token #{ids.length == 1 ? 'number' : 'numbers'} #{ids.to_sentence}: #{msg}")
  end

  public

  # Synthesises the running text of the sentence.
  #
  # The <tt>mode</tt> is :text_and_presentation if both token forms and the
  # presentation data should be included in the resulting string.
  # Presentation data from token objects and the sentence object is
  # included. :text_and_presentation_with_markup produces the same result
  # but also includes markup that distinguishes token forms from
  # presentation data. :text_only includes only token forms. Each token
  # form is then separated by a single space. The default is
  # :text_and_presentation.
  #
  # Whichever the value of <tt>mode</tt>, only tokens that are flagged as
  # non-empty contribute to the resulting string.

  def to_s(mode = :text_and_presentation)
    case mode
    when :text_only
      tokens.word.map { |token| token.to_s(:text_only) }.join(' ')
    when :text_and_presentation
      presentation_stream.map(&:last).join
    when :text_and_presentation_with_markup
      presentation_stream.map { |t, v| "<#{t}>#{v}</#{t}>" }.join
    else
      raise ArgumentError
    end
  end

  # Returns an array containing the <tt>presentation_before</tt>,
  # <tt>form</tt> and <tt>presentation_after</tt> columns and with an
  # interpretation of the presentation data. The presentation columns on
  # both tokens and sentences are included.
  #
  # The array consists of pairs of interpretation and value. Only the
  # presentation columns that have non-empty values are included in the
  # array. The interpretation is :pc for punctuation, :s for spaces and :w
  # for a (token/word) form.
  #

  def presentation_stream
    t = []

    t << [:pc, presentation_before] if presentation_before

    tokens.word.each do |token|
      t += token.presentation_stream
    end

    t << [:pc, presentation_after] if presentation_after
    t
  end

  def self.parse_presentation_markup(s)
    Nokogiri::XML("<wrap>#{s}</wrap>") do |config|
      config.strict
    end.xpath('/wrap/*').map do |n|
      [n.name.to_sym, n.children.to_s]
    end
  end

  def self.diff_presentation_stream(p1, p2)
    unless p1.map(&:last).join == p2.map(&:last).join
      raise ArgumentError, "presentation strings differ"
    end

    Diff::LCS.sdiff(p1, p2).map { |c| [c.old_element, c.new_element] }
  end

  def diff_tokenization(new_tokenization)
    # Ensure that new_tokenization is modifiable without side-effects for
    # the caller.
    new_tokenization.dup!

    # Trim Sentence.presentation_before and Sentence.presentation_after from the array.
    new_tokenization.shift if new_tokenization.first.first == :pc and new_tokenization.first.last == presentation_before
    new_tokenization.pop if new_tokenization.last.first == :pc and new_tokenization.last.last == presentation_after

    Sentence.transaction do
      tokens.each do |t|
        if new_tokenization
          if new_tokenization.first == :w
          else
          end
        else
        end
      end
    end
  end

  # Returns the maximum depth of the dependency graph, i.e. the maximum
  # distance from the root to a node in the graph in number of edges.
  def max_depth
    tokens.map(&:depth).max
  end
end
