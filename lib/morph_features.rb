require 'positional_tag'

class POSPositionalTag < PositionalTag
  def fields
    MorphFeatures::POS_POSITIONAL_TAG_SEQUENCE
  end
end

class MorphologyPositionalTag < PositionalTag
  def fields
    MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE
  end
end

# Aggregation class for morphological annotation.
class MorphFeatures
  POS_LENGTH = 2
  POS_POSITIONAL_TAG_SEQUENCE = [:major, :minor]
  MORPHOLOGY_LENGTH = 11
  MORPHOLOGY_POSITIONAL_TAG_SEQUENCE = [
    :person, :number, :tense, :mood, :voice, :gender, :case,
    :degree, :animacy, :strength, :inflection
  ]
  MORPHOLOGY_PRESENTATION_SEQUENCE = [
    :inflection, :mood, :tense, :voice, :degree, :case,
    :person, :number, :gender, :animacy, :strength
  ]

  attr_reader :lemma
  attr_reader :morphology

  def initialize(lemma, morphology)
    case lemma
    when String
      base_and_variant, pos, language = lemma.split(',')
      raise ArgumentError, "missing language" if language.blank?

      language = Language.find_by_iso_code(language)
      raise ArgumentError, "invalid language" unless language

      base, variant = base_and_variant.split('#')
      raise ArgumentError, "invalid variant" unless variant.nil? or variant.to_i > 0

      if pos and pos.gsub('-', '') != ''
        raise ArgumentError, "invalid part of speech" if pos.length > POS_LENGTH
        tag = pos.ljust(POS_LENGTH, '-')

        part_of_speech = PartOfSpeech.find_by_tag(tag)
        part_of_speech ||= PartOfSpeech.new({ :tag => tag })

        @lemma = part_of_speech.lemmata.find_by_lemma_and_variant_and_language_id(base, variant, language.id) if part_of_speech
      else
        part_of_speech = nil
      end

      unless @lemma
        @lemma = Lemma.new
        @lemma.lemma, @lemma.variant = base, variant
        @lemma.part_of_speech = part_of_speech
        @lemma.language = language
      end
    when Lemma
      raise ArgumentError, "invalid lemma" unless lemma
      @lemma = lemma
    else
      raise ArgumentError, "invalid argument"
    end

    case morphology
    when NilClass
      @morphology = nil
    when String
      if morphology and morphology.gsub('-', '') != ''
        raise ArgumentError, "invalid morphology" if morphology.length > MORPHOLOGY_LENGTH
        tag = morphology.ljust(MORPHOLOGY_LENGTH, '-')
        @morphology = Morphology.find_by_tag(tag)
        @morphology ||= Morphology.new({ :tag => tag })
      else
        @morphology = nil
      end
    when Morphology
      @morphology = morphology
    else
      raise ArgumentError, "invalid argument"
    end
  end

  def lemma_s
    [@lemma.export_form, pos_s, @lemma.language.iso_code].join(',')
  end

  # Returns the morphology as a positional tag.
  def morphology_s
    @morphology ? @morphology.tag : ('-' * MORPHOLOGY_LENGTH)
  end

  # Returns the morphology as a positional tag abbreviated as much as
  # possible. Returns nil if morphology is absent.
  def morphology_abbrev_s
    morphology_s.sub(/-+$/, '')
  end

  # Returns the morphology as a pattern suitable for matching using
  # SQL's LIKE operator.
  def morphology_as_sql_pattern
    morphology_abbrev_s.gsub('-', '_') + '%'
  end

  MORPHOLOGY_SUMMARIES = {
    :person => {
      '1' => "first person",
      '2' => "second person",
      '3' => "third person",
    },
    :number => {
      's' => 'singular',
      'd' => 'dual',
      'p' => 'plural',
    },
    :tense => {
      'p' => 'present',
      'i' => 'imperfect',
      'l' => 'pluperfect',
      'a' => 'aorist',
      'f' => 'future',
      'r' => 'perfect',
      't' => 'future perfect',
      's' => 'resultative',
      'u' => 'past',
    },
    :mood => {
      'i' => 'indicative',
      's' => 'subjunctive',
      'm' => 'imperative',
      'o' => 'optative',

      'n' => 'infinitive',
      'p' => 'participle',
      'd' => 'gerund',
      'g' => 'gerundive',
      'u' => 'supine',
    },
    :voice => {
      'a' => 'active',
      'e' => 'middle or passive',
      'm' => 'middle',
      'p' => 'passive',
    },
    :gender => {
      'o' => 'masculine or neuter',
      'p' => 'masculine or feminine',
      'q' => 'masculine, feminine or neuter',
      'r' => 'feminine or neuter',

      'm' => 'masculine',
      'f' => 'feminine',
      'n' => 'neuter',
    },
    :case => {
      'n' => 'nominative',
      'v' => 'vocative',
      'a' => 'accusative',
      'g' => 'genitive',
      'd' => 'dative',
      'b' => 'ablative',
      'i' => 'instrumental',
      'l' => 'locative',

      'c' => 'genitive or dative',
    },
    :degree => {
      'p' => 'positive',
      'c' => 'comparative',
      's' => 'superlative',
    },
    :animacy => {
      'i' => 'inanimate',
      'a' => 'animate',
    },
    :strength => {
      'w' => 'weak',
      's' => 'strong',
      't' => 'weak or strong',
    },
    :inflection => {
      'i' => 'inflecting',
      'n' => 'non-inflecting',
    }
  }

  MORPHOLOGY_ABBREVIATED_SUMMARIES = {
    :person => {
      '1' => "1st p.",
      '2' => "2nd p.",
      '3' => "3rd p.",
    },
    :number => {
      's' => 'sg.',
      'd' => 'du.',
      'p' => 'pl.',
    },
    :tense => {
      'p' => 'pres.',
      'i' => 'imperf.',
      'l' => 'ppf.',
      'a' => 'aor.',
      'f' => 'fut.',
      'r' => 'perf.',
      't' => 'fut. perf.',
      's' => 'result.',
      'u' => 'past',
    },
    :mood => {
      'i' => 'ind.',
      's' => 'subj.',
      'm' => 'imp.',
      'o' => 'opt.',

      'n' => 'inf.',
      'p' => 'part.',
      'd' => 'gerund',
      'g' => 'gerundive',
      'u' => 'sup.',
    },
    :voice => {
      'a' => 'act.',
      'e' => 'mid./pass.',
      'm' => 'mid.',
      'p' => 'pass.',
    },
    :gender => {
      'o' => 'm./n.',
      'p' => 'm./f.',
      'q' => 'm./f./n.',
      'r' => 'f./n.',

      'm' => 'm.',
      'f' => 'f.',
      'n' => 'n.',
    },
    :case => {
      'n' => 'nom.',
      'v' => 'voc.',
      'a' => 'acc.',
      'g' => 'gen.',
      'd' => 'dat.',
      'b' => 'abl.',
      'i' => 'ins.',
      'l' => 'loc.',

      'c' => 'gen./dat.',
    },
    :degree => {
      'p' => 'pos.',
      'c' => 'comp.',
      's' => 'sup.',
    },
    :animacy => {
      'i' => 'inanim.',
      'a' => 'anim.',
    },
    :strength => {
      'w' => 'weak',
      's' => 'strong',
      't' => 'weak/strong',
    },
    :inflection => {
      'i' => 'infl.',
      'n' => 'non-infl.',
    }
  }

  # === Options
  # <tt>:abbreviated</tt> -- If true, returns the summary on an
  # abbreviated format.
  # <tt>:skip_inflection</tt> -- If true, skips the +inflection+
  # field.
  def morphology_summary(options = {})
    # TODO: options
    h = morphology_to_hash
    MORPHOLOGY_PRESENTATION_SEQUENCE.map do |field|
      next if field == :inflection and h[field] == 'i' and options[:skip_inflection]
      h[field] == '-' ? nil : MORPHOLOGY_SUMMARIES[field][h[field]]
    end.compact.join(', ')
  end

  # Returns the morphology as a hash.
  def morphology_to_hash
    Hash[*MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.zip(morphology_s.split('')).flatten]
  end

  # Returns a summary description for the part of speech. Returns an
  # empty string if no part of speech is set.
  #
  # === Options
  # <tt>:abbreviated</tt> -- If true, returns the summary on an
  # abbreviated format.
  def pos_summary(options = {})
    if l = @lemma.part_of_speech
      options[:abbreviated] ? l.abbreviated_summary : l.summary
    else
      ''
    end
  end

  # Returns the part of speech as a positional tag.
  def pos_s
    @lemma.part_of_speech ? @lemma.part_of_speech.tag : ('-' * POS_LENGTH)
  end

  # Returns the language as a Language object.
  def language
    @lemma.language
  end

  # Returns the language as a language code. This is a convenience
  # function for +MorphFeatures#language.to_s+.
  def language_s
    @lemma.language.to_s
  end

  def valid?
    @lemma.lemma and @lemma.part_of_speech and @morphology and PROIEL::MorphtagConstraints.instance.is_valid?(pos_s + morphology_s, language_s.to_sym)
  end

  def union(o)
    raise ArgumentError unless o.class == MorphFeatures
    raise ArgumentError unless o.language_s == language_s
    raise ArgumentError if o.lemma.export_form and lemma.export_form and o.lemma.export_form != lemma.export_form

    new_pos = POSPositionalTag.new(pos_s).union(o.pos_s)
    new_morphology = MorphologyPositionalTag.new(morphology_s).union(o.morphology_s)

    MorphFeatures.new([@lemma.export_form || o.lemma.export_form, new_pos, language_s].join(','), new_morphology.to_s)
  end

  def contradict?(o)
    raise ArgumentError unless o.class == MorphFeatures

    return true if POSPositionalTag.new(pos_s).contradicts?(POSPositionalTag.new(o.pos_s))
    return true if MorphologyPositionalTag.new(morphology_s).contradicts?(MorphologyPositionalTag.new(o.morphology_s))

    if lemma.lemma and o.lemma.lemma
      return true if lemma.lemma != o.lemma.lemma
      return true if lemma.variant != o.lemma.variant
    end

    false
  end

  def self.pos_and_morphology_tag_space(language)
    PROIEL::MorphtagConstraints::instance.tag_space(language.to_sym).inject({}) do |k, tag|
      k[tag[0, 2]] ||= []
      k[tag[0, 2]] << tag[2, 11]
      k
    end
  end

  # Generates all possible completions of the possibly incomplete tag.
  def completions
    x = Regexp.new(/#{(pos_s + morphology_s).gsub("-", ".")}/)
    PROIEL::MorphtagConstraints::instance.tag_space(language_s.to_sym).select { |t| x.match(t) }.map do |tag|
      pos, morphology = tag[0, 2], tag[2, 11]
      MorphFeatures.new([lemma.export_form, pos, language_s].join(','), morphology)
    end
  end

  def to_features
    PROIEL::MorphtagConstraints.instance.to_features(self.to_s)
  end

  def blank?
    values.all? { |v| v.nil? }
  end

  OPEN_MAJOR = %w{V A N}

  # Returns +true+ if the features belong to one of the `closed' parts
  # of speech.
  def closed?
    pos_s[0, 1] != '-' and !OPEN_MAJOR.include?(pos_s[0, 1])
  end

  protected

  def is_gender?(value)
    raise ArgumentError.new("Invalid gender") unless ['m', 'f', 'n'].include?(value)

    case self.gender
    when 'm', 'f', 'n'
      self.gender == value
    when 'o'
      value == 'm' or value == 'n'
    when 'p'
      value == 'm' or value == 'f'
    when 'r'
      value == 'f' or value == 'n'
    when 'q'
      value == 'm' or value == 'f' or value == 'n'
    else
      false
    end
  end

  public

  # Returns +true+ if the tag is a subtag of another tag +o+.
  def subtag?(o)
    return false unless lemma_s == o.lemma_s

    # Copy the two tags in question, mask out all fields with inheritance and compare
    # the rest.
    a, b = morphology_to_hash, o.morphology_to_hash
    a[:gender], b[:gender] = '-', '-'
    return false unless a == b

    # Test the inheritable fields
    ['m', 'f', 'n'].include?(self.gender) ? o.is_gender?(self.gender) : false
  end

  # Returns +true+ if the tag is compatible with another tag +o+, i.e.
  # if the tag is a subtag of the tag +o+ or the tag is a supertag of
  # the tag +o+ or the tags are identical.
  def compatible?(o)
    self == o or subtag?(o) or o.subtag?(self)
  end

  # Returns all the morph-features as a string. This is a
  # concatenation of the various components of the morph-features'
  # string forms.
  def to_s
    [lemma_s, morphology_s].join(',')
  end

  def ==(o)
    o.is_a?(MorphFeatures) && to_s == o.to_s
  end

  def eql?(o)
    o.is_a?(MorphFeatures) && to_s == o.to_s
  end

  def hash
    to_s.hash
  end

  # Returns an integer, -1, 0 or 1, suitable for sorting morph-features.
  def <=>(o)
    raise "incompatible languages" if language != o.language

    s = pos_s <=> o.pos_s
    s = morphology_s <=> o.morphology_s if s.zero?
    s = (lemma.lemma || '') <=> (o.lemma.lemma || '') if s.zero?
    s = (lemma.variant || 0) <=> (o.lemma.variant || 0) if s.zero?
    s
  end

  def method_missing(n)
    if MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.include?(n)
      morphology_to_hash[n]
    else
      super n
    end
  end

  # TODO: move these to a +method_missing+ implementation
  def verb?
    pos_s == 'V-'
  end

  def article?
    pos_s == 'S-'
  end

  def conjunction?
    pos_s == 'C-'
  end

  def noun?
    pos_s[0, 1] == 'N'
  end

  def pronoun?
    pos_s[0, 1] == 'P'
  end

  def relative_pronoun?
    pos_s == 'Pr'
  end

  def inspect
    "#<MorphFeatures lemma=\"#{lemma_s}\" morphology=\"#{morphology_s}\">"
  end
end
