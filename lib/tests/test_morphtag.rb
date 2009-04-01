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
    assert_equal false, PROIEL::MorphTag.new('A--s---na---i').is_valid?(:lat)
    assert_equal false, PROIEL::MorphTag.new('A--s---na---i').is_valid?(:grc)
    assert_equal true, PROIEL::MorphTag.new('A--p---mdp--i').is_valid?(:lat)
    assert_equal false, PROIEL::MorphTag.new('V-3piie-----i').is_valid?(:lat)
    assert_equal true, PROIEL::MorphTag.new('V-3piie-----i').is_valid?(:grc)
    assert_equal true, PROIEL::MorphTag.new('Pd-p---nd---i').is_valid?(:lat)
    assert_equal true, PROIEL::MorphTag.new('Pi-p---mn---i').is_valid?(:lat)
    assert_equal true, PROIEL::MorphTag.new('Pk3p---mb---i').is_valid?(:lat) # personal reflexive
    assert_equal true, PROIEL::MorphTag.new('V--pppama---i').is_valid?(:lat) # present participle
    assert_equal true, PROIEL::MorphTag.new('V-2sfip-----i').is_valid?(:lat) # future indicative
    assert_equal true, PROIEL::MorphTag.new('V----u--d---i').is_valid?(:lat) # supine, dative
  end

  def test_completions
    assert_equal ["Nb----------n", "Nb-s---mn---i", "Ne----------n", "Ne-s---mn---i"], PROIEL::MorphTag.new('N--s---mn----').completions(:lat).map(&:to_s).sort
    assert_equal ["Nb-p---mn---i", "Nb-s---mn---i"], PROIEL::MorphTag.new('Nb-----mn---i').completions(:lat).map(&:to_s).sort
    assert_equal ["Nb-d---ma-a-i", "Nb-d---ma-i-i", "Nb-p---ma-a-i", "Nb-p---ma-i-i", "Nb-s---ma-a-i", "Nb-s---ma-i-i"], PROIEL::MorphTag.new('Nb-----ma---i').completions(:chu).map(&:to_s).sort
    assert_equal ["Nb-d---mn---i", "Nb-p---mn---i", "Nb-s---mn---i"], PROIEL::MorphTag.new('Nb-----mn---i').completions(:chu).map(&:to_s).sort
  end

  def test_abbrev_s
    assert_equal 'Df-------p---', PROIEL::MorphTag.new('Df-------p').to_s
    assert_equal 'Df-------p---', PROIEL::MorphTag.new('Df-------p-').to_s
    assert_equal 'Df-------p---', PROIEL::MorphTag.new('Df-------p--').to_s
    assert_equal 'Df-------p', PROIEL::MorphTag.new('Df-------p').to_abbrev_s
    assert_equal 'Df-------p', PROIEL::MorphTag.new('Df-------p-').to_abbrev_s
  end

  def test_pos_to_s
    assert_equal 'Df', PROIEL::MorphTag.new('Df-------p').pos_to_s
    assert_equal 'D-', PROIEL::MorphTag.new('D----------i').pos_to_s
  end

  def test_non_pos_to_s
    assert_equal '-s---mn---i', PROIEL::MorphTag.new('Ne-s---mn---i').non_pos_to_s
    assert_equal '-s---mn----', PROIEL::MorphTag.new('Ne-s---mn').non_pos_to_s
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

  def test_morphtags_massively
    File.open(File.join(File.dirname(__FILE__), "test_morphtag.exp")) do |f|
      f.each_line do |l|
        l.chomp!
        tag, language, validity = l.split(',')

        t = PROIEL::MorphTag.new(tag)
        l = language.to_sym
        v = (validity == 'true') ? true : false
        puts tag, t.descriptions(t.fields), l, v unless v == t.is_valid?(l)

        assert_equal v, t.is_valid?(l)
      end
    end
  end

  def test_union
    m = PROIEL::MorphTag.new('D')
    n = PROIEL::MorphTag.new('-f-------p--i')
    assert_equal 'Df-------p--i', m.union(n).to_s

    n.union!(m)
    assert_equal 'Df-------p--i', n.to_s
  end
end
