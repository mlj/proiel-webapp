#!/usr/bin/env ruby 
#
# morphtag.rb - Morphology tags
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: morphtag.rb 926 2008-04-29 15:35:12Z mariuslj $
#

require 'proiel/tagsets'
require 'extensions'

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

  class MorphTag < Hash
    PRESENTATION_SEQUENCE = [:major, :minor, :mood, :tense, :voice, :degree, :case, 
      :person, :number, :gender]

    def initialize(values = nil)
      self.default = '-'

      if values.is_a? Hash
        values.each_pair { |k, v| self[k.to_sym] = v unless v == '-' }
      elsif values.is_a? String
        values = values.ljust(MORPHOLOGY.fields.length, '-') # pad the string with -'s if necessary

        MORPHOLOGY.fields.zip(values.split('')).each { |e| 
          self[e[0]] = e[1].to_sym if e[1] != '-' }
      else
        raise "Invalid morphtag #{values}" unless values.is_a? NilClass
      end
    end

    def []=(field, value)
      raise "Invalid field #{field.inspect}. Possible fields are #{MORPHOLOGY.fields.inspect}" unless MORPHOLOGY.fields.include?(field)

      if value == '-' or value.nil?
        delete(field)
      else
        store(field, value)
      end
    end

    # Returns the tags as a string on a format suitable for storing
    # in a database or an XML file.
    def to_s
      MORPHOLOGY.fields.collect { |field| self[field] }.join
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

    # Checks a part of speech for validity and completeness.
    def self.check_pos(major, minor, language = nil)
      case major
      when :P
        return :incomplete if minor.nil? # P- 
        return :valid if [:p, :r, :d, :s, :k, :t, :c, :i, :x].include?(minor)  
      when :N
        return :incomplete if minor.nil? # N-
        return :valid if [:b, :e, :h, :j].include?(minor)  
      when :M
        return :incomplete if minor.nil? # M-
        return :valid if [:a, :o, :g].include?(minor)  
      when :D
        return :incomplete if minor.nil? # D-
        return :valid if [:f, :n, :q, :u].include?(minor)  
      when :S
        return :invalid unless language.nil? or language == :grc
        return :valid if minor.nil?
      else
        if major.nil?
          return :incomplete if minor.nil? # --
          return :incomplete if MORPHOLOGY[:minor][minor] # --
        else
          return :valid if MORPHOLOGY[:major][major] and minor.nil? # X-
        end
      end

      return :invalid
    end

    private

    FIELD_RESTRICTIONS = {
      :number => {
        :d => [[:language, :cu], [:language, :got]],
      },
      :gender => { 
        :m => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
        :f => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
        :n => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
        :o => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
        :p => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
        :q => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
        :r => [[:language, :la], [:language, :cu], [:language, :grc], [:language, :got]],
      },
      :case => {
        :v => [[:language, :la], [:language, :cu], [:language, :grc]],
        :b => [[:language, :la], [:language, :hy]],
        :i => [[:language, :cu], [:language, :hy]],
        :l => [[:language, :la], [:language, :cu], [:language, :hy]],
      },
      :tense => {
        :a => [[:language, :cu], [:language, :hy], [:language, :grc]],
      },
      :mood => {
        :o => [[:language, :grc]],
      },
      :voice => {
        :e => [[:language, :grc]],
        :m => [[:language, :grc]],
        :n => [[:language, :grc]],
        :d => [[:language, :grc]],
      },
    }

    def self.check_field_restrictions(field, value, language)
      return :incomplete if value.nil?

      if FIELD_RESTRICTIONS[field] and FIELD_RESTRICTIONS[field][value]
        restrictions = FIELD_RESTRICTIONS[field][value]
        approved = false
        restrictions.each do |restriction|
          f, v = restriction

          case f
          when :language
            approved = true if language.nil? or language == v
          end

          break if approved
        end

        return approved ? :valid : :invalid
      else
        # No restrictions on field, so valid.
        return :valid
      end
    end

    public

    # Returns true if the morphtag +x+ contradicts this morphtag.
    def contradiction?(x)
      MORPHOLOGY.fields.find { |field| self[field] != '-' and x[field] != '-' and self[field] != x[field] }
    end

    alias :contradicts? :contradiction?

    # Returns the union of the morphtag and another morphtag +x+. +x+
    # may be a MorphTag object or a string. Raises an exception if 
    # the morphtags conflict.
    #
    # Example
    #   m = MorphTag.new('D')
    #   n = MorphTag.new('-f-------p')
    #   m.union(n) # Df-------p
    def union(x)
      MorphTag.new(Lingua::PositionalTagSet.union(self.to_s, x.to_s.ljust(MORPHOLOGY.fields.length, '-')))
    end

    # Updates the morphtag to the union of itself and another morphtag +x+.
    # +x+ may be a MorphTag object or a string. Raises an exception if the 
    # morphtags conflict.
    #
    # Example
    #   m = MorphTag.new('D')
    #   n = MorphTag.new('-f-------p')
    #   m.union!(n)
    #   m # Df-------p
    def union!(x)
      s = union(x)
      MORPHOLOGY.fields.zip(s.to_s.split('')).each { |e| self[e[0]] = e[1].to_sym if e[1] != '-' }
    end

    def self.check_field(field, major, minor, mood, value, language = nil)
      return :invalid unless value.nil? or MORPHOLOGY[field][value]

      # Decide some common subcategories
      case major
      when :N, :M
        indeclinable_nominal = [:g, :h, :j].include?(minor)
      when :V
        finite_verb = [:i, :s, :m, :o].include?(mood)
      end

      # Get indeclinables out of the way right away
      return (value.nil? ? :valid : :invalid) if indeclinable_nominal

      case field
      when :person
        return check_field_restrictions(field, value, language) if finite_verb
        return check_field_restrictions(field, value, language) if (major == :P and [:p, :s, :k, :t].include?(minor))

      when :number
        if major == :V
          # :n  Infinitive   no
          # :p  Participle   yes 
          # :d  Gerund       no 
          # :g  Gerundive    yes 
          # :u  Supine       no 
          #     Rest         yes 
          return check_field_restrictions(field, value, language) if [:p, :g, :i, :s, :m, :o].include?(mood)
        else
          return check_field_restrictions(field, value, language) if [:N, :P, :M, :A, :S].include?(major)
        end

      when :gender
        if major == :V
          # :n  Infinitive   no
          # :p  Participle   yes 
          # :d  Gerund       no 
          # :g  Gerundive    yes 
          # :u  Supine       no 
          #     Rest         no
          return check_field_restrictions(field, value, language) if [:p, :g].include?(mood)
        else
          return check_field_restrictions(field, value, language) if [:N, :P, :M, :A, :S].include?(major)
        end

      when :case
        if major == :V
          # :n  Infinitive   no 
          # :p  Participle   yes 
          # :d  Gerund       yes 
          # :g  Gerundive    yes 
          # :u  Supine       yes 
          #     Rest         no
          return check_field_restrictions(field, value, language) if [:p, :d, :g, :u].include?(mood)
        else
          return check_field_restrictions(field, value, language) if [:N, :P, :M, :A, :S].include?(major)
        end

      when :mood
        return check_field_restrictions(field, value, language) if major == :V

      when :tense, :voice
        if major == :V
          # :n  Infinitive   yes 
          # :p  Participle   yes 
          # :d  Gerund       no 
          # :g  Gerundive    no 
          # :u  Supine       no 
          #     Rest         yes 
          return check_field_restrictions(field, value, language) unless [:d, :g, :u].include?(mood) 
        end

      when :degree
        return check_field_restrictions(field, value, language) if major == :A or (major == :D and minor == :f) # adjective or comparable adverb

      when :extra
        # Everything goes
        return :valid

      else
        raise "Invalid field #{field}"
      end

      return value.nil? ? :valid : :invalid
    end

    # Returns all possible values for POS-fields.
    def self.pos_values(language = nil)
      p = []
      MORPHOLOGY[:major].values.each do |major|
        m = MORPHOLOGY[:minor].values
        m << nil
        m.each do |minor|
          if minor
            p.push([major.code, major.summary, minor.code, minor.summary]) if check_pos(major.code, minor.code, language) == :valid
          else
            p.push([major.code, major.summary, nil, nil]) if check_pos(major.code, nil, language) == :valid
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
            next unless check_pos(major.code, minor_code, language) == :valid

            n = MORPHOLOGY[:mood].values
            n << nil
            n.each do |mood|
              mood_code = mood ? mood.code : nil
              p.push([major.code, minor_code, mood_code, f.code, f.summary]) if check_field(field, major.code, minor_code, mood_code, f.code, language) == :valid
            end
          end
        end
      end
      p
    end

    # Generates all possible completions of a particular field of the 
    # current tag.
    def field_completions(field, language = nil)
      MORPHOLOGY[field].keys.reject { |code| contradiction?(MorphTag.new(field => code)) }
    end

    # Generates all possible completions of the possibly incomplete tag.
    def completions(language = nil)
      me = self.to_s
      candidates = {}
      fields = MORPHOLOGY.fields.reject { |field| field == :extra } #FIXME

      # See what we can complete this with
      for field in fields
        candidates[field] = field_completions(field, language)
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

    # Checks the tag for completion and validity. If +language+ is set, will
    # take language into account.
    def status(language = nil)
      s = MorphTag.check_pos(self.fetch(:major) { nil },
                             self.fetch(:minor) { nil },
                             language)
      return s if s == :invalid

      MORPHOLOGY.keys.each do |field|
        next if field == :major or field == :minor

        t = MorphTag.check_field(field, 
                                 self.fetch(:major) { nil },
                                 self.fetch(:minor) { nil },
                                 self.fetch(:mood) { nil },
                                 self.fetch(field) { nil },
                                 language)

        return t if t == :invalid # Invalid trumphs everything
        s = t if t == :incomplete # Incomplete trumphs everything but invalid
      end

      return s
    end

    # Returns +true+ if the tag is valid, i.e. if the subset of fields
    # with a value match the constraints on the fields. If +language+ is
    # set, will take language into account when validating.
    def valid?(language = nil)
      s = status(language)
      s == :valid || s == :incomplete
    end

    # Returns +true+ if the tag is complete, i.e. if the entire subset of
    # fields allowed to have a value by the constraints on the fields,
    # have a value. If +language+ is set, will take language into account
    # when testing for completion.
    def complete?(language = nil)
      s = status(language)
      s == :valid
    end

    # Returns +true+ if the tag is empty, i.e. uninitialised.
    def empty?
      keys.length == 0
    end

    # Tests if the tag is equal in value to another tag.
    def ==(other)
      self.to_s == other.to_s
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
  end
end

if $0 == __FILE__
  require 'test/unit'
  include PROIEL

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
      assert_equal :valid, MorphTag.check_pos(:F, nil)
      assert_equal :valid, MorphTag.check_pos(:N, :e)
      assert_equal :valid, MorphTag.check_pos(:D, :f)
      assert_equal :valid, MorphTag.check_pos(:M, :a)
      assert_equal :invalid, MorphTag.check_pos(:D, :e)
      assert_equal :invalid, MorphTag.check_pos(:P, :q)
      assert_equal :incomplete, MorphTag.check_pos(:P, nil)
      assert_equal :incomplete, MorphTag.check_pos(:D, nil)
      assert_equal :incomplete, MorphTag.check_pos(:M, nil)
      assert_equal :incomplete, MorphTag.check_pos(:N, nil)
      assert_equal :incomplete, MorphTag.check_pos(nil, nil)
      assert_equal :incomplete, MorphTag.check_pos(nil, :f)
      assert_equal :invalid, MorphTag.check_pos(nil, :y)
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

    def test_equality
      a = MorphTag.new('Nb-s---mn')
      b = MorphTag.new('Nb-s---mn--')
      assert_equal true, a == b
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
