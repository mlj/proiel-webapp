class Sentence < ActiveRecord::Base
  belongs_to :source_division
  has_many :bookmarks
  has_many :notes, :as => :notable, :dependent => :destroy

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

  before_validation :before_validation_cleanup

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

  # Presentation string must be on the appropriate Unicode normalization form
  validates_unicode_normalization_of :presentation, :form => UNICODE_NORMALIZATION_FORM

  validate :check_invariants
  validate do |s|
    unless s.presentation_well_formed?
      s.errors.add_to_base('Presentation string is not well-formed.')
    end
  end

  acts_as_audited :except => [:annotated_by, :annotated_at, :reviewed_by, :reviewed_at, :reference_fields]

  # Returns the language for the sentence.
  def language
    source_division.language
  end

  include Presentation

  # Returns the sentence and its context as an array of sentences. +n+
  # specifies the number of sentences to count as the sentence's
  # 'context'.
  def sentences_in_context(n = 5)
    previous_sentences.last(n) + [self] + next_sentences.first(n)
  end

  #FIXME:DRY generalise < token

  def previous_sentences(include_previous_sd = false)
    ps = source_division.sentences.find(:all,
                                   :conditions => [ "sentence_number < ?", sentence_number ],
                                   :order => "sentence_number ASC")
    ps = source_division.previous.sentences.find(:all, :order => "sentence_number ASC" ) + ps if include_previous_sd and source_division.previous
    ps
  end

  def next_sentences
    source_division.sentences.find(:all,
                                   :conditions => [ "sentence_number > ?", sentence_number ],
                                   :order => "sentence_number ASC")
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

  include References

  def reference_parent
    parent
  end

  # Re-indexes the references.
  def reindex!
    Sentence.transaction do
      unless has_previous?
        self.reference_fields = self.presentation_as_reference
        source_division.save!
      else
        # Merge with what we had in the last sentence, but only keep
        # the last element in arrays or ranges, and always overwrite
        # with new information.
        self.reference_fields = previous.last_of_reference_fields.merge(presentation_as_reference)
        raise "Referencing inconsistency: source division unexpectedly changed" if source_division.changed?
      end

      save!
    end
  end

  # Remove all dependency annotation from a sentence and save the changes.
  # This will also do away with any empty tokens in the sentence, and
  # change the annotation and review state of the sentence.
  def clear_dependencies!
    tokens.each { |token| token.update_attributes!(:relation => nil, :head => nil) }

    # Remove all empty tokens from a sentence
    Token.delete_all :sentence_id => self.id, :form => nil

    self.annotated_by = nil
    self.annotated_at = nil
    self.reviewed_by = nil
    self.reviewed_at = nil
    save!
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
        node.slashes_with_interpretations.each { |slashee, interpretation| SlashEdge.create(:slasher => token,
                                                       :slashee_id => id_map[slashee.identifier],
                                                       :relation => Relation.find_by_tag(interpretation) ) }
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
          :language => language.iso_code,
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
      pick, *suggestions = token.inferred_morph_features

      # Figure out which morph-features to use as the displayed value.
      # Anything already set in the editor or, alternatively, in the
      # morph-features trumphs whatever the tagger spews out.
      if x = overlaid_features["morph-features-#{token.id}".to_sym] #FIXME
        set = MorphFeatures.new(x)
        state = :annotated
      elsif token.morph_features
        set = token.morph_features
        state = :annotated
      elsif pick
        set = pick
        state = suggestions.length > 1 ? :ambiguous : :unambiguous
      else
        set = nil
        state = :ambiguous
      end

      [token, set, suggestions, state]
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

  # Appends the next sentence onto this sentence and destroys the old
  # sentence. This also removed all dependency annotation from both
  # sentences to ensure validity.
  def append_next_sentence!(nondestructive = false)
    if has_next?
      Sentence.transaction do
        if nondestructive
          append_tokens!(next_sentence.tokens)
        else
          detokenize!
          # next_sentence's tokens will be removed when sentence is destroyed.
        end

        self.presentation = self.presentation + '<s> </s>' + self.next_sentence.presentation
        save!
        tokenize!

        next_sentence.destroy
      end
    else
      raise "No next sentence"
    end
  end

  # Split the sentence into a number of sentences. Undoes tokenization
  # of the sentence and thus also removes all annotation from the
  # sentence. The symbol or regular expression used for segment splits
  # is given in +segment_divider+. If the new segmentation produces
  # only one segment, the presentation string for this sentence is
  # updated but no new sentence objects are created.
  def split_sentence!(presentation_string, segment_divider = /\s*\|\s*/)
    raise ArgumentError if presentation_string.blank?

    presentation_strings = presentation_string.split(segment_divider)

    n = presentation_strings.length - 1

    if n.zero?
      self.presentation = presentation_string
      self.save!
    else
      Sentence.transaction do
        detokenize!

        # We need to shift all sentence numbers after this one first. Do it in
        # reverse order to avoid confusing the indices.
        ses = parent.sentences.find(:all, :conditions => ["sentence_number > ?", sentence_number])
        ses.sort { |x, y| y.sentence_number <=> x.sentence_number }.each do |s|
          s.sentence_number += n
          s.save!
        end

        # Update presentation strings.
        self.presentation = presentation_strings[0]
        self.save!
        self.reindex!
        self.tokenize!

        1.upto(n).map do |i|
          s = parent.sentences.create!(:sentence_number => sentence_number + i,
                                       :presentation => presentation_strings[i])
          s.reference_fields = self.reference_fields
          s.save!
          s.reindex!
          s.tokenize!
        end
      end
    end
  end

  # Creates a new token and appends it to the end of the sentence. The
  # function is equivalent to +create!+ except for the automatic
  # positioning of the new token in the sentence's linearization
  # sequence.
  def append_new_token!(attrs = {})
    tokens.create!(attrs.merge({ :token_number => max_token_number + 1 }))
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

  # Move the +n+ first tokens from the next sentence to the end of
  # this sentence and save the affected records.
  def append_first_tokens_from_next_sentence!(n = 1)
    if self.has_next_sentence?
      append_tokens!(self.next_sentence.tokens.first(n))
    else
      raise "No next sentence"
    end
  end

  # Move the +n+ last token from the previous sentence to the
  # beginning of this sentence and save the affected records.
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
  def dependency_graph
    PROIEL::ValidatingDependencyGraph.new do |g|
      tokens.dependency_annotatable.each { |t| g.badd_node(t.id, t.relation.tag, t.head ? t.head.id : nil,
                                               Hash[*t.slash_out_edges.map { |se| [se.slashee.id, se.relation.tag] }.flatten],
                                               { :empty => t.empty_token_sort || false,
                                                 :token_number => t.token_number,
                                                 :morph_features => t.morph_features,
                                                 :form => t.form }) }
    end
  end

  # Returns +true+ if sentence has information structure annotation.
  def has_information_structure_annotation?
    # FIXME: Should probably be improved. At least we can tell that we
    # won't have any annotation unless dependency annotation is
    # present.
    has_dependency_annotation?
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

  # Tokenizes the sentence using the current tokenization rules.
  # The function has no effect on a sentence that has already been
  # tokenized.
  def guess_tokenization!
    # TODO: Major FIXME: this is specific to Latin and does not even
    # do a good job with that language. But it has to do for now...
    presentation_as_text.gsub('á', 'a').gsub('é', 'e').gsub('í', 'i').gsub('ó', 'o').gsub('ú', 'u').gsub(/[†#\?\[\]]/, '').gsub(/\s*["'—]\s*/,' ').gsub(/[\.]\s*$/, '').gsub(/[,;:]\s*/, ' ').gsub('onust', 'onus est').gsub(/(occasio)st/, '\1 est').gsub(/(aeris|senatus|re|rem|rei|res)\s+(alieni|consulto|publica|publicam|publicae)/, '\1#\2').split(/\s+/).map do |t|
      if t[/^(.*)que$/]
        base = $1
        unless t[/^pler(us|um|i|o|a|am|ae|os|orum|is|as|arum)que$/] or t[/^([Aa]t|[Ii]ta|[Nn]e)que$/]
          [base, '-que']
        else
          t
        end
      else
        t.gsub('#', ' ')
      end
    end.flatten.each_with_index do |form, position|
      self.tokens.create! :form => form, :token_number => position, :empty_token_sort => nil
    end
  end

  # Tokenizes a sentence using the tokenization mark-up in the
  # presentation string.
  #
  # If invoked on a sentence that has been tokenized before, the
  # existing tokenization is undone and all annotation is removed.
  def tokenize!
    Sentence.transaction do
      detokenize! if tokenized?

      presentation_as_tokens.each_with_index do |form, position|
        # FIXME: Deal with reference_fields.
        tokens.create! :form => form, :token_number => position, :empty_token_sort => nil
      end
    end
  end

  # Compares tokenization based on the presentation string with actual
  # tokenization, if any. Returns true if the tokenization is
  # identical, i.e. valid, or if the sentence has not been tokenized.
  def tokenization_valid?
    # This will be ordered by token number, and that is all we need except the form.
    t = tokens.word.map(&:form)
    p = presentation_as_tokens

    !tokenized? or p == t
  end

  # Undoes any tokenization of the sentence. All annotation is also
  # removed.
  def detokenize!
    Sentence.transaction do
      tokens.map(&:destroy)
      tokens.reload
      self.annotated_by = nil
      self.annotated_at = nil
      self.reviewed_by = nil
      self.reviewed_at = nil
      save!
    end
  end

  # Returns true if the sentence has been tokenized, false otherwise.
  def tokenized?
    !tokens.word.length.zero?
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

  private

  def before_validation_cleanup
    self.presentation = nil if presentation.blank?
  end

  public

  def to_s
    presentation_as_text
  end
end
