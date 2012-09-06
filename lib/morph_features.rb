require 'positional_tag'
require 'yaml'

class Morphology < PositionalTag
  def morphology
    tag
  end

  def size
    10
  end

  def fields
    [:person, :number, :tense, :mood, :voice, :gender, :case,
     :degree, :strength, :inflection]
  end
end

class PartOfSpeech
  attr_reader :tag, :summary, :abbreviated_summary

  alias :to_s :tag
  alias :to_label :summary

  def initialize(tag)
    @tag = tag

    if PartOfSpeechTag.include?(tag)
      t = PartOfSpeechTag[tag]
      @summary = t.summary
      @abbreviated_summary = t.abbreviated_summary
    else
      @summary = nil
      @abbreviated_summary = nil
    end
  end

  def valid?
    PartOfSpeechTag.include?(tag)
  end

  # Returns an array of all parts of speech.
  def self.all
    PartOfSpeechTag.all
  end

  def fields
    [:major, :minor]
  end

  # Returns a hash with part of speech tags as keys and summaries as
  # values.
  def self.tag_and_summary_hash
    PartOfSpeechTag.all
  end

  def major
    @tag.split('').first
  end

  def minor
    @tag.split('').last
  end

  def contradicts?(tag)
    @tag.split('').zip(tag.tag.split('')).any? do |x, y|
      x && x != '-' && y && y != '-' && x != y
    end
  end

  alias :part_of_speech :tag
end

# Aggregation class for morphological annotation.
class MorphFeatures
  POS_LENGTH = 2
  MORPHOLOGY_LENGTH = 10
  MORPHOLOGY_POSITIONAL_TAG_SEQUENCE = [
    :person, :number, :tense, :mood, :voice, :gender, :case,
    :degree, :strength, :inflection
  ]
  MORPHOLOGY_PRESENTATION_SEQUENCE = [
    :inflection, :mood, :tense, :voice, :degree, :case,
    :person, :number, :gender, :strength
  ]

  attr_reader :lemma
  attr_reader :morphology

  def initialize(lemma, morphology)
    case lemma
    when String
      base_and_variant, pos, language = lemma.split(',')
      raise ArgumentError, "missing language" if language.blank?

      language = LanguageTag.find(language)
      raise ArgumentError, "invalid language" unless language

      base, variant = base_and_variant.split('#')
      raise ArgumentError, "invalid variant" unless variant.nil? or variant.to_i.to_s == variant

      if pos and pos.gsub('-', '') != ''
        pos = pos + '-' if pos.length == 1
        part_of_speech = PartOfSpeech.new(pos)

        @lemma = Lemma.find_by_part_of_speech_tag_and_lemma_and_variant_and_language(part_of_speech.tag, base, variant, language) if part_of_speech
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
        @morphology = Morphology.new(morphology)
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
    [@lemma.export_form, pos_s, @lemma.language.tag].join(',')
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

  MORPHOLOGY_ALL_SUMMARIES = YAML.load_file(Rails.root.join(Proiel::Application.config.tagset_file_path, 'morphology.yml')).inject({}) do |m, v|
    m[v[0]] = v[1].inject({}) { |m2, v2| m2[v2[0]] = v2[1]; m2 }
    m
  end

  MORPHOLOGY_SUMMARIES = YAML.load_file(Rails.root.join(Proiel::Application.config.tagset_file_path, 'morphology.yml')).inject({}) do |m, v|
    m[v[0]] = v[1].inject({}) { |m2, v2| m2[v2[0]] = v2[1]["summary"]; m2 }
    m
  end

  MORPHOLOGY_ABBREVIATED_SUMMARIES = YAML.load_file(Rails.root.join(Proiel::Application.config.tagset_file_path, 'morphology.yml')).inject({}) do |m, v|
    m[v[0]] = v[1].inject({}) { |m2, v2| m2[v2[0]] = v2[1]["abbreviated_summary"]; m2 }
    m
  end

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
      if options[:abbreviated]
        h[field] == '-' ? nil : MORPHOLOGY_ABBREVIATED_SUMMARIES[field][h[field]]
      else
        h[field] == '-' ? nil : MORPHOLOGY_SUMMARIES[field][h[field]]
      end
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

  # Returns the language as a language tag. This is a convenience
  # function for +MorphFeatures#language.to_s+.
  def language_s
    @lemma.language.to_s
  end

  def valid?
    @lemma.lemma and @lemma.part_of_speech and @morphology and MorphtagConstraints.instance.is_valid?(pos_s + morphology_s, language_s.to_sym)
  end

  def contradict?(o)
    raise ArgumentError unless o.class == MorphFeatures

    return true if PartOfSpeech.new(pos_s).contradicts?(PartOfSpeech.new(o.pos_s))
    return true if Morphology.new(morphology_s).contradicts?(Morphology.new(o.morphology_s))

    if lemma.lemma and o.lemma.lemma
      return true if lemma.lemma != o.lemma.lemma
      return true if lemma.variant != o.lemma.variant
    end

    false
  end

  def self.pos_and_morphology_tag_space(language)
    MorphtagConstraints::instance.tag_space(language.to_sym).inject({}) do |k, tag|
      k[tag[0, 2]] ||= []
      k[tag[0, 2]] << tag[2, 11]
      k
    end
  end

  # Generates all possible completions of the possibly incomplete tag.
  def completions
    x = Regexp.new(/#{(pos_s + morphology_s).gsub("-", ".")}/)
    MorphtagConstraints::instance.tag_space(language_s.to_sym).select { |t| x.match(t) }.map do |tag|
      pos, morphology = tag[0, 2], tag[2, 11]
      MorphFeatures.new([lemma.export_form, pos, language_s].join(','), morphology)
    end
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
    raise "incompatible languages #{language.inspect} and #{o.language.inspect}" if language != o.language

    s = pos_s <=> o.pos_s
    s = morphology_s <=> o.morphology_s if s.zero?
    s = (lemma.lemma || '') <=> (o.lemma.lemma || '') if s.zero?
    s = (lemma.variant || 0) <=> (o.lemma.variant || 0) if s.zero?
    s
  end

  POS_PREDICATES = {
    :verb? => 'V-',
    :article? => 'S-',
    :conjunction? => 'C-',
    :noun? => 'N',
    :pronoun? => 'P',
    :relative_pronoun? => 'Pr',
    :preposition? => 'R-',
  }

  def method_missing(n)
    if MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.include?(n)
      morphology_to_hash[n]
    elsif POS_PREDICATES.has_key?(n)
      if POS_PREDICATES[n].length == 1
        pos_s[0, 1] == POS_PREDICATES[n]
      else
        pos_s == POS_PREDICATES[n]
      end
    else
      super n
    end
  end

  def inspect
    "#<MorphFeatures lemma=\"#{lemma_s}\" morphology=\"#{morphology_s}\">"
  end
end
