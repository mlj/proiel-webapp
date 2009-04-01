require File.dirname(__FILE__) + '/../test_helper'

class MorphLemmaTagTestCase < ActiveSupport::TestCase
  def test_separate_initialisation
    m = PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new('Dq'), 'cur')
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal nil, m.variant
    assert_equal "Dq-----------:cur", m.to_s
    assert_equal "Dq:cur", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new('Dq'), 'cur#2')
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq-----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new(PROIEL::MorphTag.new('Dq'), 'cur', 2)
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq-----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq', 'cur#2')
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq-----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq', 'cur', 2)
    assert_equal 'cur', m.lemma
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 2, m.variant
    assert_equal "Dq-----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s
  end

  def test_string_initialization
    m = PROIEL::MorphLemmaTag.new('Dq')
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal nil, m.lemma
    assert_equal nil, m.variant
    assert_equal "Dq-----------", m.to_s
    assert_equal "Dq", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq', nil)
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal nil, m.lemma
    assert_equal nil, m.variant
    assert_equal "Dq-----------", m.to_s
    assert_equal "Dq", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq:cur')
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 'cur', m.lemma
    assert_equal nil, m.variant
    assert_equal "Dq-----------:cur", m.to_s
    assert_equal "Dq:cur", m.to_abbrev_s

    m = PROIEL::MorphLemmaTag.new('Dq:cur#2')
    assert_equal PROIEL::MorphTag.new('Dq'), m.morphtag
    assert_equal 'cur', m.lemma
    assert_equal 2, m.variant
    assert_equal "Dq-----------:cur#2", m.to_s
    assert_equal "Dq:cur#2", m.to_abbrev_s
  end

  def test_comparison
    assert_equal 0, PROIEL::MorphLemmaTag.new('Dq:cur#2') <=> PROIEL::MorphLemmaTag.new('Dq:cur#2')

    assert_equal -1, PROIEL::MorphLemmaTag.new('Dq:cur#1') <=> PROIEL::MorphLemmaTag.new('Dq:cur#2')
    assert_equal 1, PROIEL::MorphLemmaTag.new('Dq:cur#2') <=> PROIEL::MorphLemmaTag.new('Dq:cur#1')

    assert_equal -1, PROIEL::MorphLemmaTag.new('A:cur#1') <=> PROIEL::MorphLemmaTag.new('Dq:cur#1')
    assert_equal 1, PROIEL::MorphLemmaTag.new('Pr:cur#1') <=> PROIEL::MorphLemmaTag.new('Dq:cur#1')

    assert_equal -1, PROIEL::MorphLemmaTag.new('Dq:cum#1') <=> PROIEL::MorphLemmaTag.new('Dq:cur#1')
    assert_equal 1, PROIEL::MorphLemmaTag.new('Dq:sine#1') <=> PROIEL::MorphLemmaTag.new('Dq:cur#1')

    assert_equal -1, PROIEL::MorphLemmaTag.new('Dq:cum') <=> PROIEL::MorphLemmaTag.new('Dq:cum#1')
    assert_equal 1, PROIEL::MorphLemmaTag.new('Dq:cum#1') <=> PROIEL::MorphLemmaTag.new('Dq:cum')

    assert_equal -1, PROIEL::MorphLemmaTag.new('Dq') <=> PROIEL::MorphLemmaTag.new('Dq:cum')
    assert_equal 1, PROIEL::MorphLemmaTag.new('Dq:cum') <=> PROIEL::MorphLemmaTag.new('Dq')

    assert_equal -1, PROIEL::MorphLemmaTag.new('Dq') <=> PROIEL::MorphLemmaTag.new('Dq:cum#1')
    assert_equal 1, PROIEL::MorphLemmaTag.new('Dq:cum#1') <=> PROIEL::MorphLemmaTag.new('Dq')
  end
end
