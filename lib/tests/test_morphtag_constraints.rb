#!/usr/bin/env ruby

require 'proiel/morphtag_constraints'
require 'test/unit'

class MorphtagConstraintsTestCase < Test::Unit::TestCase
  def test_simple
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('V-3sfip-----', :lat)
    assert_equal false, m.is_valid?('V-----------', :lat)
    assert_equal true, m.is_valid?('A--p---fac--', :lat)
    assert_equal false, m.is_valid?('D-----------', :chu)
  end

  def test_animacy
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('Nb-p---fd---', :chu)
    assert_equal false, m.is_valid?('Nb-p---fd-i-', :chu)
    assert_equal true, m.is_valid?('Nb-p---fa---', :chu)
    assert_equal false, m.is_valid?('Nb-p---fa-i-', :chu)
    assert_equal true, m.is_valid?('Nb-p---md---', :chu)
    assert_equal false, m.is_valid?('Nb-p---md-i-', :chu)

    assert_equal false, m.is_valid?('Nb-p---ma---', :chu)
    assert_equal true, m.is_valid?('Nb-p---ma-i-', :chu)
  end
end
