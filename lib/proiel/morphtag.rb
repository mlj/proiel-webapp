#!/usr/bin/env ruby 
#
# morphtag.rb - Morphology tags
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'proiel/tagsets'
require 'proiel/morphtag_constraints'
require 'proiel/positional_tag'

module PROIEL
  MorphLemmaTag = Struct::new(:morphtag, :lemma, :variant)

  class MorphLemmaTag
    def initialize(morphtag_or_string, lemma = nil, variant = nil)
      if morphtag_or_string.is_a?(String) and lemma.nil? and variant.nil?
        morphtag, rest = morphtag_or_string.split(':')
        lemma, variant = rest.split('#') if rest

        super(MorphTag.new(morphtag), lemma, variant ? variant.to_i : nil)
      else
        morphtag = morphtag_or_string.is_a?(String) ? MorphTag.new(morphtag_or_string) : morphtag_or_string
        lemma, variant = lemma.split('#') unless variant

        super(morphtag, lemma, variant ? variant.to_i : nil)
      end
    end

    def lemma_to_s
      v = self.variant ? "##{self.variant}" : ''
      l = self.lemma ? "#{self.lemma}" : ''
      l + v
    end

    def to_s
      l = lemma_to_s
      l != '' ? "#{self.morphtag}:#{l}" : self.morphtag.to_s
    end

    def to_abbrev_s
      l = lemma_to_s
      l != '' ? "#{self.morphtag.to_abbrev_s}:#{l}" : self.morphtag.to_abbrev_s
    end

    def eql?(o)
      o.is_a?(MorphLemmaTag) && to_s == o.to_s
    end

    def hash
      to_s.hash 
    end

    def ==(o)
      o.is_a?(MorphLemmaTag) && to_s == o.to_s
    end
  end

  class MorphTag < Logos::PositionalTag
    PRESENTATION_SEQUENCE = [:major, :minor, :mood, :tense, :voice, :degree, :case, 
      :person, :number, :gender]

    def initialize(values = nil)
      values = PROIEL::MorphTag.pad_s(values) if values.is_a?(String)

      super
    end

    def self.pad_s(s)
      s.ljust(MORPHOLOGY.fields.length, '-')
    end

    def fields
      MORPHOLOGY.fields
    end

    # Returns the tag as an string, abbreviated as much as possible.
    def to_abbrev_s
      to_s.sub(/-+$/, '')
    end

    # Returns the part-of-speech part of the morphtag as a string.
    def pos_to_s
      "#{self[:major]}#{self[:minor]}"
    end

    # Returns descriptions for one or more fields in a tag. If
    # +inclusive+ is +true+, +fields+ is an array of fields to
    # include in the description. If +fields+ is +false+, +fields+
    # is an array of fields to exclude. The descriptions are
    # returned as an array of strings. 
    #
    # ==== Options
    # style:: If +:abbreviation+, returns the description on abbreviated form whenever possible.
    # If +:summary+, returns the description as a summary. Default is +:summary+.
    def descriptions(fields, inclusive = true, options = {})
      f = inclusive ? fields : PRESENTATION_SEQUENCE.reject { |field| fields.include?(field) }
      f.collect { |field| self[field] != '-' ?
        MORPHOLOGY.descriptions(field, options)[self[field]] : nil }.compact
    end

    def union(x)
      super(x.to_s.ljust(fields.length, '-'))
    end

    private

    def self.check_field_is_valid?(field, major, minor, mood, value, language = nil)
      return :invalid unless value.nil? or MORPHOLOGY[field][value]

      q = MorphTag.new({ :major => major, :minor => minor, :mood => mood,
                         field => value })
      PROIEL::MorphtagConstraints.instance.is_valid?(q.to_s, language)
    end

    def self.check_pos_is_valid?(major, minor, language = nil)
      q = MorphTag.new({ :major => major, :minor => minor })
      PROIEL::MorphtagConstraints.instance.is_valid?(q.to_s, language)
    end

    public

    # Returns all possible values for POS-fields.
    def self.pos_values(language = nil)
      p = []
      MORPHOLOGY[:major].values.each do |major|
        m = MORPHOLOGY[:minor].values
        m << nil
        m.each do |minor|
          if minor
            p.push([major.code, major.summary, minor.code, minor.summary]) if check_pos_is_valid?(major.code, minor.code, language)
          else
            p.push([major.code, major.summary, nil, nil]) if check_pos_is_valid?(major.code, nil, language)
          end
        end
      end
      p
    end

    # Returns all possible values for non-POS fields. 
    def self.field_values(field, language = nil)
      p = []
      MORPHOLOGY[:major].values.each do |major|
        m = MORPHOLOGY[:minor].values
        m << nil
        m.each do |minor|
          MORPHOLOGY[field].values.each do |f|
            minor_code = minor ? minor.code : nil
            next unless check_pos_is_valid?(major.code, minor_code, language)

            n = MORPHOLOGY[:mood].values
            n << nil
            n.each do |mood|
              mood_code = mood ? mood.code : nil
              p.push([major.code, minor_code, mood_code, f.code, f.summary]) if check_field_is_valid?(field, major.code, minor_code, mood_code, f.code, language)
            end
          end
        end
      end
      p
    end

    # Generates all possible completions of the possibly incomplete tag.
    def completions(language = nil)
      me = self.to_s
      candidates = {}
      fields = MORPHOLOGY.fields.reject { |field| field == :extra } #FIXME

      # See what we can complete this with
      for field in fields
        candidates[field] = MORPHOLOGY[field].keys.select do |code| 
          m = MorphTag.new(field => code)
          !contradicts?(m)
        end
      end

      # Cut down the forest by eliminating invalid combinations. Compose
      # tags from left to right and recurse whenever we have somthing that
      # is valid.
      result = (rec = lambda do |fields, result|
        if fields.empty?
          return result
        else
          new_result = []
          field = fields.head 

          result.each do |m|
            candidates[field].each do |candidate|
              m[field] = candidate
              new_result << m.dup if m.valid?(language)
            end

            # This additional test cuts down time a lot; an empty
            # major field will never lead to a complete tag.
            unless field == :major
              m[field] = nil 
              new_result << m.dup if m.valid?(language)
            end
          end

          return rec[fields.tail, new_result]
        end
      end)[fields, [MorphTag.new]]

      # Filter away the incompletes
      result.select { |m| m.complete?(language) }
    end

    # Returns +true+ if the tag is valid, i.e. if the subset of fields
    # with a value match the constraints on the fields. If +language+ is
    # set, will take language into account when validating.
    def is_valid?(language = nil)
      PROIEL::MorphtagConstraints.instance.is_valid?(self.to_s, language)
    end

    alias valid? is_valid?

    # Returns +true+ if the tag is complete, i.e. if the entire subset of
    # fields allowed to have a value by the constraints on the fields,
    # have a value. If +language+ is set, will take language into account
    # when testing for completion.
    def is_complete?(language = nil)
      PROIEL::MorphtagConstraints.instance.is_complete?(self.to_s, language)
    end

    alias complete? is_complete?

    # Returns +true+ if the tag is empty, i.e. uninitialised.
    def empty?
      keys.length == 0
    end

    # Returns true if gender has value +value+ or a value that is
    # a super-tag for +value+.
    def is_gender?(value)
      raise ArgumentError.new("Invalid gender") unless [:m, :f, :n].include?(value)

      case self[:gender]
      when :m, :f, :n
        self[:gender] == value
      when :o
        value == :m or value == :n
      when :p
        value == :m or value == :f
      when :r
        value == :f or value == :n
      when :q
        value == :m or value == :f or value == :n
      else
        false
      end
    end

    private

    CLOSED_MAJOR = [:V, :A, :N]

    def self.fields_with_inheritance
      [:gender]
    end

    public

    # Returns +true+ if the tag belongs to one of the `closed' parts
    # of speech.
    #
    # Examples:
    #  MorphTag.new('C').is_closed?  #-> true
    #  MorphTag.new('A').is_closed?  #-> false
    #  MorphTag.new('-').is_closed?  #-> false
    def is_closed?
      self.has_key?(:major) and not CLOSED_MAJOR.include?(self[:major])
    end

    # Returns +true+ if the tag is a subtag of another tag +o+.
    #
    # Examples (assuming that the defined field in the examples
    # represents gender, and that 'q' is a supertag for 'n'):
    #
    #   MorphTag.new('-------n---').is_subtag?(MorphTag.new('-------q---'))  #-> true
    #   MorphTag.new('-------q---').is_subtag?(MorphTag.new('-------n---'))  #-> false
    #   MorphTag.new('-------n---').is_subtag?(MorphTag.new('-----------'))  #-> false
    #   MorphTag.new('-----------').is_subtag?(MorphTag.new('-------n---'))  #-> false
    def is_subtag?(o)
      # Copy the two tags in question, mask out all fields with inheritance and compare
      # the rest.
      a, b = self.dup, o.dup
      a[*MorphTag::fields_with_inheritance], b[*MorphTag::fields_with_inheritance] = nil, nil
      return false unless a == b

      # Test the inheritable fields
      [:m, :f, :n].include?(self[:gender]) ? o.is_gender?(self[:gender]) : false
    end

    # Returns +true+ if the tag is compatible with another tag +o+, i.e.
    # if the tag is a subtag of the tag +o+ or the tag is a supertag of
    # the tag +o+ or the tags are identical.
    #
    # Examples (assuming that the defined field in the examples
    # represents gender, and that 'q' is a supertag for 'n'):
    #
    #   MorphTag.new('-------n---').is_compatible?(MorphTag.new('-------q---'))  #-> true
    #   MorphTag.new('-------q---').is_compatible?(MorphTag.new('-------n---'))  #-> true
    #   MorphTag.new('-------n---').is_compatible?(MorphTag.new('-----------'))  #-> false
    #   MorphTag.new('-----------').is_compatible?(MorphTag.new('-------n---'))  #-> false
    def is_compatible?(o)
      self == o or self.is_subtag?(o) or o.is_subtag?(self)
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  include PROIEL

  class MorphTagTestCase < Test::Unit::TestCase
    def test_is_closed
      assert_equal false, PROIEL::MorphTag.new('V').is_closed?
      assert_equal false, PROIEL::MorphTag.new('V-').is_closed?
      assert_equal false, PROIEL::MorphTag.new('-').is_closed?
      assert_equal false, PROIEL::MorphTag.new('N').is_closed?
      assert_equal false, PROIEL::MorphTag.new('A').is_closed?
      assert_equal true, PROIEL::MorphTag.new('C').is_closed?
    end

    def test_is_subtag
      assert_equal true, PROIEL::MorphTag.new('-------n---').is_subtag?(PROIEL::MorphTag.new('-------q---'))
      assert_equal false, PROIEL::MorphTag.new('-------q---').is_subtag?(PROIEL::MorphTag.new('-------n---'))
      assert_equal false, PROIEL::MorphTag.new('-------n---').is_subtag?(PROIEL::MorphTag.new('-----------'))
      assert_equal false, PROIEL::MorphTag.new('-----------').is_subtag?(PROIEL::MorphTag.new('-------n---'))

      assert_equal true, PROIEL::MorphTag.new('A------n---').is_subtag?(PROIEL::MorphTag.new('A------q---'))
      assert_equal false, PROIEL::MorphTag.new('P------n---').is_subtag?(PROIEL::MorphTag.new('A------q---'))
    end

    def test_is_compatible
      assert_equal true, PROIEL::MorphTag.new('-------n---').is_compatible?(PROIEL::MorphTag.new('-------q---'))
      assert_equal true, PROIEL::MorphTag.new('-------q---').is_compatible?(PROIEL::MorphTag.new('-------n---'))
      assert_equal false, PROIEL::MorphTag.new('-------n---').is_compatible?(PROIEL::MorphTag.new('-----------'))
      assert_equal false, PROIEL::MorphTag.new('-----------').is_compatible?(PROIEL::MorphTag.new('-------n---'))

      assert_equal true, PROIEL::MorphTag.new('A------n---').is_compatible?(PROIEL::MorphTag.new('A------q---'))
      assert_equal false, PROIEL::MorphTag.new('P------n---').is_compatible?(PROIEL::MorphTag.new('A------q---'))
    end
  end

  class MorphologyTestCase < Test::Unit::TestCase
    def setup
      @c = MorphTag.new('V-3spia----')
      @d = MorphTag.new('-----------')
    end

    def test_default
      assert_equal '-' * 11, @d.to_s
    end

    def test_presentation_sequence
      # FIXME: This will fail until we get rid of :extra
      #assert_equal MORPHOLOGY.fields.collect { |f| f.to_s }.sort, MorphTag::PRESENTATION_SEQUENCE.collect { |f| f.to_s }.sort
    end

    def test_descriptions_pos
      assert_equal ['verb'], @c.descriptions([:major, :minor])
    end

    def test_descriptions_nonpos
      assert_equal ['indicative', 'present', 'active', 'third person', 'singular'], @c.descriptions([:major, :minor], false)
    end

    def test_description_undef_pos
      assert_equal [], @d.descriptions([:major, :minor])
    end

    def test_description_undef_nonpos
      assert_equal [], @d.descriptions([:major, :minor], false)
    end

    def test_pos_validity
      assert_equal true, MorphTag.check_pos_is_valid?(:F, nil)
      assert_equal true, MorphTag.check_pos_is_valid?(:N, :e)
      assert_equal true, MorphTag.check_pos_is_valid?(:D, :f)
      assert_equal true, MorphTag.check_pos_is_valid?(:M, :a)
      assert_equal false, MorphTag.check_pos_is_valid?(:D, :e)
      assert_equal false, MorphTag.check_pos_is_valid?(:P, :q)
      assert_equal true, MorphTag.check_pos_is_valid?(:P, nil)
      assert_equal true, MorphTag.check_pos_is_valid?(:D, nil)
      assert_equal true, MorphTag.check_pos_is_valid?(:M, nil)
      assert_equal true, MorphTag.check_pos_is_valid?(:N, nil)
      assert_equal false, MorphTag.check_pos_is_valid?(nil, nil)
      assert_equal false, MorphTag.check_pos_is_valid?(nil, :f)
      assert_equal false, MorphTag.check_pos_is_valid?(nil, :y)
    end

    def test_validity
      assert_equal true, MorphTag.new('A--s---na--').valid?
      assert_equal true, MorphTag.new('A--s---na--').valid?(:la)
      assert_equal true, MorphTag.new('A--s---na--').valid?(:grc)
      assert_equal true, MorphTag.new('A--p---mdp-').valid?
      assert_equal true, MorphTag.new('A--p---mdp-').valid?(:la)

      # Indicative, imperfect, middle or passive deponent, third person, plural
      assert_equal true, MorphTag.new('V-3piin----').valid?
      assert_equal false, MorphTag.new('V-3piin----').valid?(:la)
      assert_equal true, MorphTag.new('V-3piin----').valid?(:grc)
    end

    def test_pos_values
      #assert_equal 16, MorphTag.pos_values.length
    end

    def test_completeness
      assert_equal false, MorphTag.new('A--s---na--').complete?
      assert_equal false, MorphTag.new('A--s---na--').complete?(:la)
      assert_equal false, MorphTag.new('A--s---na--').complete?(:grc)

      assert_equal true, MorphTag.new('Pd-p---nd--').complete?(:la)
      assert_equal true, MorphTag.new('Pi-p---mn--').complete?(:la)
      assert_equal true, MorphTag.new('Pk3p---mb--').complete?(:la) # personal reflexive
      assert_equal true, MorphTag.new('V--pppama--').complete?(:la) # present participle
      assert_equal true, MorphTag.new('V-2sfip----').complete?(:la) # future indicative
      assert_equal true, MorphTag.new('V----u--d--').complete?(:la) # supine, dative
    end

    def test_completions
      assert_equal ["Nb-s---mn--","Ne-s---mn--", "Nh---------", "Nj---------"], MorphTag.new('N--s---mn-').completions.collect { |t| t.to_s }.sort
      assert_equal ["Nb-p---mn--","Nb-s---mn--"], MorphTag.new('Nb-----mn-').completions(:la).collect { |t| t.to_s }.sort
      assert_equal ["Nb-d---mn--","Nb-p---mn--","Nb-s---mn--"], MorphTag.new('Nb-----mn-').completions(:cu).collect { |t| t.to_s }.sort
    end

    def test_union
      m = MorphTag.new('D')
      n = MorphTag.new('-f-------p')
      assert_equal 'Df-------p-', m.union(n).to_s

      n.union!(m)
      assert_equal 'Df-------p-', n.to_s
    end

    def test_abbrev_s
      assert_equal 'Df-------p-', MorphTag.new('Df-------p').to_s
      assert_equal 'Df-------p-', MorphTag.new('Df-------p-').to_s
      assert_equal 'Df-------p', MorphTag.new('Df-------p').to_abbrev_s
      assert_equal 'Df-------p', MorphTag.new('Df-------p-').to_abbrev_s
    end

    def test_pos_to_s
      assert_equal 'Df', MorphTag.new('Df-------p').pos_to_s
      assert_equal 'D-', MorphTag.new('D----------').pos_to_s
    end

    def test_morph_lemma_tag
      m = MorphLemmaTag.new(MorphTag.new('Dq'), 'cur')
      assert_equal 'cur', m.lemma
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal nil, m.variant
      assert_equal "Dq---------:cur", m.to_s
      assert_equal "Dq:cur", m.to_abbrev_s

      m = MorphLemmaTag.new(MorphTag.new('Dq'), 'cur#2')
      assert_equal 'cur', m.lemma
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal 2, m.variant
      assert_equal "Dq---------:cur#2", m.to_s
      assert_equal "Dq:cur#2", m.to_abbrev_s

      m = MorphLemmaTag.new(MorphTag.new('Dq'), 'cur', 2)
      assert_equal 'cur', m.lemma
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal 2, m.variant
      assert_equal "Dq---------:cur#2", m.to_s
      assert_equal "Dq:cur#2", m.to_abbrev_s

      m = MorphLemmaTag.new('Dq', 'cur#2')
      assert_equal 'cur', m.lemma
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal 2, m.variant
      assert_equal "Dq---------:cur#2", m.to_s
      assert_equal "Dq:cur#2", m.to_abbrev_s

      m = MorphLemmaTag.new('Dq', 'cur', 2)
      assert_equal 'cur', m.lemma
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal 2, m.variant
      assert_equal "Dq---------:cur#2", m.to_s
      assert_equal "Dq:cur#2", m.to_abbrev_s
    end

    def test_morph_lemma_tag_string_initialization
      m = MorphLemmaTag.new('Dq')
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal nil, m.lemma
      assert_equal nil, m.variant
      assert_equal "Dq---------", m.to_s
      assert_equal "Dq", m.to_abbrev_s

      m = MorphLemmaTag.new('Dq', nil)
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal nil, m.lemma
      assert_equal nil, m.variant
      assert_equal "Dq---------", m.to_s
      assert_equal "Dq", m.to_abbrev_s

      m = MorphLemmaTag.new('Dq:cur')
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal 'cur', m.lemma
      assert_equal nil, m.variant
      assert_equal "Dq---------:cur", m.to_s
      assert_equal "Dq:cur", m.to_abbrev_s

      m = MorphLemmaTag.new('Dq:cur#2')
      assert_equal MorphTag.new('Dq'), m.morphtag
      assert_equal 'cur', m.lemma
      assert_equal 2, m.variant
      assert_equal "Dq---------:cur#2", m.to_s
      assert_equal "Dq:cur#2", m.to_abbrev_s
    end

    def test_is_gender
      m = MorphTag.new('Px-s---mn--')
      assert_equal true, m.is_gender?(:m)
      assert_equal false, m.is_gender?(:f)
      assert_equal false, m.is_gender?(:n)

      m = MorphTag.new('Px-s---qn--')
      assert_equal true, m.is_gender?(:m)
      assert_equal true, m.is_gender?(:f)
      assert_equal true, m.is_gender?(:n)
    end
  end
end
