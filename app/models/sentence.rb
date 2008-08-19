class Sentence < ActiveRecord::Base
  belongs_to :book
  belongs_to :source
  has_many :bookmarks
  has_many :notes, :as => :notable, :dependent => :destroy

  belongs_to :annotator, :class_name => 'User', :foreign_key => 'annotated_by'
  belongs_to :reviewer, :class_name => 'User', :foreign_key => 'reviewed_by'

  has_and_belongs_to_many :aligned_with, :class_name => 'Sentence', :join_table => 'sentence_alignments', :foreign_key => 'primary_sentence_id', :association_foreign_key => 'secondary_sentence_id'

  # All tokens
  has_many :tokens, :order => 'token_number'

  # All tokens with dependents included
  has_many :tokens_with_dependents, :class_name => 'Token',
     :include => :dependents, :order => 'tokens.token_number'

  # Tokens that can be tagged with dependency relations.
  has_many :dependency_tokens, :class_name => 'Token', :foreign_key => 'sentence_id',
    :conditions => { "sort" => PROIEL::DEPENDENCY_TOKEN_SORTS }, :order => 'token_number'

  # Tokens that can be tagged with morphology and lemma.
  has_many :morphtaggable_tokens, :class_name => 'Token', :foreign_key => 'sentence_id',
    :conditions => { "sort" => PROIEL::MORPHTAGGABLE_TOKEN_SORTS }, :order => 'token_number'

  # Tokens that are non-empty.
  has_many :nonempty_tokens, :class_name => 'Token', :foreign_key => 'sentence_id',
    :conditions => { "sort" => PROIEL::NON_EMPTY_TOKEN_SORTS }, :order => 'token_number'

  # General schema-defined validations

  validates_presence_of :source_id
  validates_presence_of :book_id
  validates_presence_of :chapter
  validates_presence_of :sentence_number

  validate :check_invariants

  acts_as_audited :except => [ :annotated_by, :annotated_at, :reviewed_by, :reviewed_at ]

  #FIXME:DRY generalise < token

  def previous_sentences
    self.source.sentences.find(:all,
                               :conditions => [ "sentence_number < ? and book_id = ?", self.sentence_number, self.book_id ],
                               :order => "sentence_number ASC")
  end

  def next_sentences
    self.source.sentences.find(:all,
                               :conditions => [ "sentence_number > ? and book_id = ?", self.sentence_number, self.book_id ],
                               :order => "sentence_number ASC")
  end

  # Returns the previous sentence in the linearisation sequence. Returns +nil+
  # if there is no previous sentence.
  def previous_sentence
    self.source.sentences.find(:first,
                               :conditions => [ "sentence_number < ? and book_id = ?", self.sentence_number, self.book_id ],
                               :order => "sentence_number DESC")
  end

  # Returns the next sentence in the linearisation sequence. Returns +nil+
  # if there is no next sentence.
  def next_sentence
    self.source.sentences.find(:first,
                               :conditions => [ "sentence_number > ? and book_id = ?", self.sentence_number, self.book_id ],
                               :order => "sentence_number ASC")
  end

  # Returns true if there is a previous sentence.
  def has_previous_sentence?
    !previous_sentence.nil?
  end

  # Returns true if there is a next sentence.
  def has_next_sentence?
    !next_sentence.nil?
  end

  # Returns a reference for the sentence.
  def reference
    PROIEL::Reference.new(source.abbreviation, source.id, book.code, book.id,
                  { :chapter => chapter, :verse => nonempty_tokens.first.verse..nonempty_tokens.last.verse,
                    :sentence => sentence_number })
  end

  # Returns the language of the sentence.
  def language
    # FIXME: eliminate to_sym
    source.language.to_sym
  end

  # Remove all dependency annotation from a sentence and save the changes.
  # This will also do away with any empty tokens in the sentence.
  def clear_dependencies!
    tokens.each { |token| token.clear_dependencies! }
    delete_all_empty_tokens!
  end

  # Remove all empty tokens from a sentence
  def delete_all_empty_tokens!
    Token.delete_all :sentence_id => self.id, :form => nil
  end

  # Updates the dependency structure of a sentence from a hash. This
  # sets the relation and head columns of all affected tokens in the
  # sentence and saves them.
  def update_dependencies!(structure, new_ids, parent = nil)
    # We will append new empty nodes at the end of the token sequence. Establish
    # which token_number to start at.
    @new_token_number ||= max_token_number + 1

    structure.each_pair do |token_id, value|
      t = nil
      if token_id[/^new/]
        # Append an empty token at the end of the sentence. The token
        # will not have its verse number set as the sentence may cross
        # verse boundaries. The verse number of the empty token is therefore
        # undefined.
        t = Token.new(:sentence_id => id, :token_number => @new_token_number, :sort => :empty_dependency_token)
        @new_token_number += 1
      else
        # Perform some extra sanity checking here. All token IDs in the structure
        # should match our records. Otherwise we have been given bad token IDs
        # by the UI or the database has changed underneath us.
        if Token.exists?(token_id)
          t = Token.find(token_id)
        else
          raise "Invalid token ID #{token_id} in when updating dependencies"
        end
      end
      t.update_dependencies!(parent ? parent.id : nil, value['relation'])

      # Keep track of the new IDs for later use
      new_ids[token_id] = t.id if token_id[/^new/]

      update_dependencies!(value['dependents'], new_ids, t) if value['dependents']
    end
  end

  # Returns the slash structure for the sentence. The slashes are given
  # as an array of slasher and slashee tokens.
  def slashes
    current_slashes = []

    tokens.each do |token|
      token.slashees.each do |slashee|
        current_slashes << [token, slashee]
      end
    end

    current_slashes
  end

  # Updates the slash structure for the sentence. The slashes are given as
  # an array of slasher and slashees. Any existing slashes not in the new
  # list will be destroyed.
  def update_slashes!(slashes)
    current_slashes = []
    tokens.each do |token|
      token.slash_out_edges.each do |edge|
        # Read this by using slash_out_edges and the IDs directly, as
        # the target nodes may very well be gone by now.
        current_slashes << [edge.slasher_id, edge.slashee_id]
      end
    end

    remove = (current_slashes - slashes).compact
    add = (slashes - current_slashes).compact

    remove.each do |slasher_id, slashee_id|
      s = SlashEdge.find_by_slasher_id_and_slashee_id(slasher_id, slashee_id)
      s.destroy
    end

    add.each do |slasher_id, slashee_id|
      SlashEdge.add_edge(slasher_id, slashee_id)
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

  # Appends the next sentence onto this sentence and destroys the old next
  # sentence. This should be protected by a transaction.
  def append_next_sentence!
    if succ
      succ.tokens.each do |token|
        append_token!(token)
      end
      succ.destroy!
    end
  end

  def split_sentence!
    if not tokens.length.zero?
      Sentence.transaction do
        # We need to shift all sentence numbers after this one first. Do it in reverse order
        # just to be cool.
        ses = Sentence.find(:all, :conditions => [
          "source_id = ? and book_id = ? and sentence_number > ?",
          source.id, book.id, sentence_number
        ])
        ses.sort { |x, y| y.sentence_number <=> x.sentence_number }.each do |s|
          s.sentence_number += 1
          s.save!
        end

        # Copy all attributes
        # FIXME: update this
        new_s = Sentence.create(:source_id => source.id, :book_id => book.id, :chapter => chapter)
        new_s.sentence_number = sentence_number + 1
        new_s.save!

        # Finally, shuffle our last token over to the new sentence.
        new_s.prepend_token!(tokens.last)
      end
    end
  end

  # Append tokens to this sentence by reassigning its sentence and token number
  # and save the affected record.
  def append_tokens!(tokens)
    tokens.each do |t|
      t.sentence_id = id
      t.token_number = self.max_token_number + 1
      t.save!
    end
  end

  # Prepend tokens to this sentence by reassigning sentence and token numbers
  # and save the affected records.
  def prepend_tokens!(ts)
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

  # Reassign the +n+ first token of the next sentence to the end of
  # this sentence and save the affected record.
  def append_first_tokens_from_next_sentence!(n = 1)
    if self.has_next_sentence?
      append_tokens!(self.next_sentence.tokens.first(n))
    else
      raise "No next sentence"
    end
  end

  # Reassign the +n+ last token of the previous sentence to the
  # beginning of this sentence and save the affected record.
  def prepend_last_tokens_from_previous_sentence!(n = 1)
    if self.has_previous_sentence?
      prepend_tokens!(self.previous_sentence.tokens.last(n))
    else
      raise "No previous sentence"
    end
  end

  # Returns +true+ if sentence has been annotated.
  def is_annotated?
    !annotated_by.nil?
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
    !reviewed_by.nil?
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
  def dependency_structure
    s = {}
    dependency_tokens.each do |token|
      # Merge data about this token into the result structure
      s[token.id] ||= { :dependents => {} }
      s[token.id].merge!({
        :relation => token.relation,
        :found => true,
        :empty => token.is_empty?,
        :slashes => token.slashees.collect(&:id)
      })

      # Attach this token to its head's list of dependents
      head = token.head ? token.head_id : :root
      s[head] ||= { :dependents => {} }
      s[head][:dependents][token.id] = s[token.id]
    end

    # Return the dependents of the ficticious root node
    s[:root][:dependents]
  end

  # Returns the dependency graph for the sentence.
  def dependency_graph
    PROIEL::ValidatingDependencyGraph.new do |g|
      dependency_tokens.each { |t| g.badd_node(t.id, t.relation, t.head ? t.head.id : nil,
                                               t.slashees.collect(&:id),
                                               { :empty => t.is_empty?,
                                                 :token_number => t.token_number,
                                                 :morphtag => PROIEL::MorphTag.new(t.morphtag),
                                                 :form => t.form }) }
    end
  end

  # Returns the tokens that are immediate descendants of the root node
  # in the dependency structure of the sentence.
  def root_tokens
    dependency_tokens.reject { |t| t.head }
  end

  # Returns +true+ if sentence has dependency annotation.
  def has_dependency_annotation?
    @has_dependency_annotation ||= dependency_tokens.first && !dependency_tokens.first.relation.nil?
  end

  # Returns +true+ if sentence has morphological annotation (i.e.
  # morphtag + lemma).
  def has_morphological_annotation?
    # Assumed invariant: morphologically annotated sentence <=> all
    # morphology tokens have non-nil morphtag and lemma_id attributes.
    @has_morphological_annotation ||= morphtaggable_tokens.first && !morphtaggable_tokens.first.morphtag.nil?
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
    if dependency_tokens.any?(&:relation) and not dependency_tokens.all?(&:relation)
      errors.add_to_base("Dependency annotation must be complete")
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
end
