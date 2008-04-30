require 'proiel'
require 'hooks'

class Token < ActiveRecord::Base
  belongs_to :sentence
  belongs_to :book
  belongs_to :lemma

  belongs_to :head, :class_name => 'Token'
  has_many :dependents, :class_name => 'Token', :foreign_key => 'head_id'

  has_many :slash_out_edges, :class_name => 'SlashEdge', :foreign_key => 'slasher_id'
  has_many :slash_in_edges, :class_name => 'SlashEdge', :foreign_key => 'slashee_id'
  has_many :slashees, :through => :slash_out_edges
  has_many :slashers, :through => :slash_in_edges

  acts_as_audited :except => [ :morphtag_performance ]
  # Insanely slow! We use our own implementation instead.
  #acts_as_ordered :order => :token_number

  # General schema-defined validations
  validates_presence_of :sentence_id
  validates_presence_of :verse, :if => :nonempty? 
  validates_presence_of :token_number
  # Ensure that relation != '' (instead of NULL)
  validates_length_of :relation, :minimum => 1, :allow_nil => true
  validates_presence_of :composed_form, :if => lambda { |t| t.sort == :composed_form }
  validates_presence_of :sort

  # Specific validations

  validate :validate_sort

  def previous_tokens
    self.sentence.tokens.find(:all, 
                              :conditions => [ "token_number < ?", self.token_number ], 
                              :order => "token_number ASC")
  end

  def next_tokens
    self.sentence.tokens.find(:all, 
                              :conditions => [ "token_number > ?", self.token_number ], 
                              :order => "token_number ASC")
  end

  # Returns the previous token in the linearisation sequence. Returns +nil+
  # if there is no previous token.
  def previous_token
    self.sentence.tokens.find(:first, 
                              :conditions => [ "token_number < ?", self.token_number ], 
                              :order => "token_number DESC")
  end

  # Returns the next token in the linearisation sequence. Returns +nil+
  # if there is no next token.
  def next_token
    self.sentence.tokens.find(:first, 
                              :conditions => [ "token_number > ?", self.token_number ], 
                              :order => "token_number ASC")
  end

  def morph
    PROIEL::MorphTag.new(morphtag)
  end

  # Returns the morph+lemma tag for the token or +nil+ if none
  # is set.
  def morph_lemma_tag
    if self.morphtag
      if lemma
        PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new(morphtag), 
                                  lemma.lemma, lemma.variant)
      else
        PROIEL::MorphLemmaTag.new(morphtag)
      end
    else
      nil
    end
  end

  # Sets morphology and lemma based on a morph+lemma tag. Saves the
  # token.
  def set_morph_lemma_tag!(ml_tag)
    returning Lemma.find_or_create_by_morph_and_lemma_tag_and_language(ml_tag, self.language) do |l|
      self.morphtag = ml_tag.morphtag.to_s
      self.lemma_id = l.id
      self.save!
    end
  end

  # Returns the source morph+lemma tag for the token or +nil+ if
  # none is set.
  def source_morph_lemma_tag
    if self.source_morphtag
      PROIEL::MorphLemmaTag.new(self.source_morphtag, self.source_lemma)
    else
      nil
    end
  end

  def reference
    if verse
      PROIEL::Reference.new(sentence.source.abbreviation, sentence.source.id,
                    sentence.book.code, sentence.book.id,
                    { :chapter => sentence.chapter.to_i, 
                      :verse => verse.to_i, 
                      :sentence => sentence.sentence_number.to_i, 
                      :token => token_number.to_i })
    else
      PROIEL::Reference.new(sentence.source.abbreviation, sentence.source.id,
                    sentence.book.code, sentence.book.id,
                    { :chapter => sentence.chapter.to_i, 
                      :sentence => sentence.sentence_number.to_i, 
                      :token => token_number.to_i })
    end
  end

  # Updates dependency annotation for the token and saves the record.
  def update_dependencies!(head, relation)
    self.head_id = head
    self.relation = relation
    save!
  end

  # Clears dependency annotation for the token and saves the record.
  def clear_dependencies!
    update_dependencies!(nil, nil)
  end

  # Returns true if this is an empty token, i.e. a token used for empty nodes
  # in dependency structures.
  def empty?
    sort == :empty
  end

  # Returns true if this is a non-empty token.
  def nonempty?
    !empty?
  end

  # Returns true if this is a puctuation token.
  def punctuation?
    sort == :nonspacing_punctuation
  end

  # Returns true if this is a fused morpheme.
  def fused_morpheme?
    sort == :fused_morpheme
  end

  # Returns true if this is an enclitic.
  def enclitic?
    sort == :enclitic
  end

  # Returns true if this is a token that takes part in morphology tagging.
  def morphtaggable?
    (not empty?) and (not punctuation?)
  end

  # Invokes the PROIEL morphology tagger. Takes exitsing information into
  # account, be it already existing morph+lemma tags or previous instances
  # of the same token form.
  def invoke_tagger
    TAGGER.logger = logger
    TAGGER.tag_token(self.language, self.form, self.sort, 
                     self.morph_lemma_tag || self.source_morph_lemma_tag)
  end

  # Returns the language of the token.
  def language
    # FIXME: eliminate to_sym
    sentence.source.language.to_sym
  end 

  # Merges the token with the token linearly subsequent to it. The succeding
  # token is destroyed, and the original token's word form is updated. All
  # other data is left as-is. Returns the new merged token.
  def merge!(separator = ' ')
    Token.transaction do
      n = self.next_token
      self.form = [self.form, n.form].join(separator)
      self.save!
      n.destroy
    end
    self
  end

  # Splits the token into two linearly adjacent tokens. The original
  # token's data is left as-is, and the new token, whose linear
  # position is immediately after the original token, is returned for
  # further initialisation. The creation of a new token and all token
  # number changes are saved.
  def split!(new_form, new_sort, new_composed_form = nil)
    # Shift token numbers after the old token numbers. We have to do the numbers
    # in descending order to avoid duplicates keys in the sentence_id, token_number 
    # index.
    sentence.tokens.reject { |t| t.token_number <= self.token_number }.sort_by(&:token_number).reverse.each do |t|
      t.token_number += 1
      t.save!
    end

    sentence.tokens.create!(:verse => self.verse,
                            :token_number => self.token_number + 1,
                            :form => new_form,
                            :composed_form => new_composed_form,
                            :sort => new_sort)
  end

  # Splits the token into two linearly adjactent tokens representing
  # a fused morpheme. The original token's data is left as-is except
  # for the form which is stripped of the fused morpheme. The new
  # token is returned.
  def split_fused_morpheme!(fused_morpheme_form)
    if self.form[/^(.*)#{fused_morpheme_form}$/]
      Token.transaction do
        n = self.split!(fused_morpheme_form, :fused_morpheme, self.form)
        self.form = $1
        self.save!
        n
      end
    else
      raise "Fused morpheme form '#{fused_morpheme_form}' is not a suffix of original token's form '#{self.form}'."
    end
  end

  protected

  def self.search(search, page, limit = 50)
    search ||= {}
    conditions = [] 
    clauses = [] 
    includes = []

    if search[:source] and search[:source] != ''
      clauses << "sentences.source_id = ?"
      conditions << search[:source]
      includes << :sentence
    end
    
    if search[:form] and search[:form] != ''
      if search[:exact] == 'yes'
        clauses << "form = ?"
        conditions << "#{search[:form]}"
      else
        clauses << "form like ?"
        conditions << "%#{search[:form]}%"
      end
    end
    
    morphtag = PROIEL::MorphTag.new
    [:major, :minor, :person, :number, :tense, :mood, :voice, :gender, :case, :degree, :extra].each do |field|
      if search[field] and search[field] != ''
        morphtag[field] = search[field]
      end
    end

    if morphtag.to_s != '-----------'
      clauses << "morphtag like ?"
      conditions << morphtag.to_s.gsub('-', '_')
    end

    conditions = [clauses.join(' and ')] + conditions

    paginate(:page => page, :per_page => limit, :conditions => conditions, 
             :include => includes)
  end

  private

  def validate_sort
    # morphtag and morphtag source may only be set 
    # if token is morphtaggable
    unless morphtaggable?
      errors.add(:morphtag, "not allowed on non-morphtaggable token") unless morphtag.nil?
      errors.add(:morphtag_source, "not allowed on non-morphtaggable token") unless morphtag_source.nil?
    end

    # if morphtag is set, is it valid?
    if morphtag
      errors.add_to_base("Morphological annotation #{morphtag.inspect} is invalid") unless PROIEL::MorphTag.new(morphtag).valid?(self.language)
    end

    # if morphtag is set, is it actually a morphtag or just a blank?
    if morphtag
      errors.add(:morphtag, "is blank (probably should be NULL)") if morphtag == ''
      errors.add(:morphtag, "is blank (probably should be NULL)") if morphtag == PROIEL::MorphTag.new().to_s 
    end

    # sort :empty <=> form.nil?
    if sort == :empty or form.nil?
      errors.add_to_base("Empty tokens must have NULL form and sort set to 'empty'") unless sort == :empty and form.nil?
    end

    # sort :fused_morpheme <=> !composed_form.nil? 
    if sort == :fused_morpheme or !composed_form.nil?
      errors.add_to_base("Fused morpheme tokens must have a composed form and sort set to 'fused_morpheme'") unless sort == :fused_morpheme and !composed_form.nil?
    end
  end
end
