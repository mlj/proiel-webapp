#!/usr/bin/env ruby

require 'proiel/morphtag'
require 'test/unit'

class MorphtagTestCase < Test::Unit::TestCase
  def setup
    @c = PROIEL::MorphTag.new('V-3spia----')
    @d = PROIEL::MorphTag.new('-----------')
  end

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

  def test_default
    assert_equal '-' * PROIEL::MorphTag.fields.length, @d.to_s
  end

  def test_presentation_sequence
    # FIXME: This will fail until we get rid of :extra
    #assert_equal MORPHOLOGY.fields.collect { |f| f.to_s }.sort, PROIEL::MorphTag::PRESENTATION_SEQUENCE.collect { |f| f.to_s }.sort
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

  def test_validity
    assert_equal false, PROIEL::MorphTag.new('A--s---na--').is_valid?(:la)
    assert_equal false, PROIEL::MorphTag.new('A--s---na--').is_valid?(:grc)
    assert_equal true, PROIEL::MorphTag.new('A--p---mdp-').is_valid?(:la)
    assert_equal false, PROIEL::MorphTag.new('V-3piin----').is_valid?(:la)
    assert_equal true, PROIEL::MorphTag.new('V-3piin----').is_valid?(:grc)
    assert_equal true, PROIEL::MorphTag.new('Pd-p---nd--').is_valid?(:la)
    assert_equal true, PROIEL::MorphTag.new('Pi-p---mn--').is_valid?(:la)
    assert_equal true, PROIEL::MorphTag.new('Pk3p---mb--').is_valid?(:la) # personal reflexive
    assert_equal true, PROIEL::MorphTag.new('V--pppama--').is_valid?(:la) # present participle
    assert_equal true, PROIEL::MorphTag.new('V-2sfip----').is_valid?(:la) # future indicative
    assert_equal true, PROIEL::MorphTag.new('V----u--d--').is_valid?(:la) # supine, dative
  end

  def test_completions
    assert_equal ["Nb-s---mn---","Ne-s---mn---", "Nh----------", "Nj----------"], PROIEL::MorphTag.new('N--s---mn-').completions(:la).collect { |t| t.to_s }.sort
    assert_equal ["Nb-p---mn---","Nb-s---mn---"], PROIEL::MorphTag.new('Nb-----mn--').completions(:la).collect { |t| t.to_s }.sort
    assert_equal ["Nb-d---ma-a-","Nb-d---ma-i-","Nb-p---ma-a-","Nb-p---ma-i-","Nb-s---ma-a-","Nb-s---ma-i-"], PROIEL::MorphTag.new('Nb-----ma--').completions(:cu).collect { |t| t.to_s }.sort
    assert_equal ["Nb-d---mn---","Nb-p---mn---","Nb-s---mn---"], PROIEL::MorphTag.new('Nb-----mn--').completions(:cu).collect { |t| t.to_s }.sort
  end

  def test_abbrev_s
    assert_equal 'Df-------p--', PROIEL::MorphTag.new('Df-------p').to_s
    assert_equal 'Df-------p--', PROIEL::MorphTag.new('Df-------p-').to_s
    assert_equal 'Df-------p--', PROIEL::MorphTag.new('Df-------p--').to_s
    assert_equal 'Df-------p', PROIEL::MorphTag.new('Df-------p').to_abbrev_s
    assert_equal 'Df-------p', PROIEL::MorphTag.new('Df-------p-').to_abbrev_s
  end

  def test_pos_to_s
    assert_equal 'Df', PROIEL::MorphTag.new('Df-------p').pos_to_s
    assert_equal 'D-', PROIEL::MorphTag.new('D----------').pos_to_s
  end

  def test_non_pos_to_s
    assert_equal '-s---mn---', PROIEL::MorphTag.new('Ne-s---mn---').non_pos_to_s
    assert_equal '-s---mn---', PROIEL::MorphTag.new('Ne-s---mn').non_pos_to_s
  end

  def test_morph_lemma_tag
    m = PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new('Dq'), 'cur')
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal nil, m.variant
    assert_equal "Dq----------:cur", m.to_s
    assert_equal "Dq:cur", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new('Dq'), 'cur#2')
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new('Dq'), 'cur', 2)
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq', 'cur#2')
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq', 'cur', 2)
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s
  end

  def test_morph_lemma_tag_string_initialization
    m = PROIEL::MorphLemmaTag.new('Dq')
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal nil, m.lemma
    assert_equal nil, m.variant
    assert_equal "Dq----------", m.to_s
    assert_equal "Dq", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq', nil)
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal nil, m.lemma
    assert_equal nil, m.variant
    assert_equal "Dq----------", m.to_s
    assert_equal "Dq", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq:cur')
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 'cur', m.lemma
    assert_equal nil, m.variant
    assert_equal "Dq----------:cur", m.to_s
    assert_equal "Dq:cur", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq:cur#2')
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 'cur', m.lemma
    assert_equal 2, m.variant
    assert_equal "Dq----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s
  end

  def test_is_gender
    m = PROIEL::MorphTag.new('Px-s---mn---')
    assert_equal true, m.is_gender?(:m)
    assert_equal false, m.is_gender?(:f)
    assert_equal false, m.is_gender?(:n)

    m = PROIEL::MorphTag.new('Px-s---qn---')
    assert_equal true, m.is_gender?(:m)
    assert_equal true, m.is_gender?(:f)
    assert_equal true, m.is_gender?(:n)
  end
end

def test_morphtags_massively
  File.open(File.join(File.dirname(__FILE__), "test_morphtag.exp")) do |f|
    f.each_line do |l|
      l.chomp!
      tag, language, validity = l.split(',')

      t = PROIEL::MorphTag.new(tag)
      l = language.to_sym
      v = (validity == 'true') ? true : false
      puts t.descriptions(t.fields), l, v unless v == t.is_valid?(l)

      assert_equal v, t.is_valid?(l)
    end
  end

  def test_union
    m = PROIEL::MorphTag.new('D')
    n = PROIEL::MorphTag.new('-f-------p')
    assert_equal 'Df-------p-', m.union(n).to_s

    n.union!(m)
    assert_equal 'Df-------p-', n.to_s
  end
end
