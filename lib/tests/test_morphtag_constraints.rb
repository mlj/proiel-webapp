#!/usr/bin/env ruby

require 'proiel/morphtag_constraints'
require 'test/unit'

class MorphtagConstraintsTestCase < Test::Unit::TestCase
  def test_simple
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('V-3sfip-----', :la)
    assert_equal false, m.is_valid?('V-----------', :la)
    assert_equal true, m.is_valid?('A--p---fac--', :la)
    assert_equal false, m.is_valid?('D-----------', :cu)
  end

  def test_animacy
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('Nb-p---fd---', :cu)
    assert_equal false, m.is_valid?('Nb-p---fd-i-', :cu)
    assert_equal true, m.is_valid?('Nb-p---fa---', :cu)
    assert_equal false, m.is_valid?('Nb-p---fa-i-', :cu)
    assert_equal true, m.is_valid?('Nb-p---md---', :cu)
    assert_equal false, m.is_valid?('Nb-p---md-i-', :cu)

    assert_equal false, m.is_valid?('Nb-p---ma---', :cu)
    assert_equal true, m.is_valid?('Nb-p---ma-i-', :cu)
  end
end
