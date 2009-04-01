#!/usr/bin/env ruby

require 'proiel/morphtag_constraints'
require 'test/unit'

class MorphtagConstraintsTestCase < Test::Unit::TestCase
  def test_simple
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('V-3sfip-----i', :lat)
    assert_equal false, m.is_valid?('V-----------i', :lat)
    assert_equal true, m.is_valid?('A--p---fac--i', :lat)
    assert_equal false, m.is_valid?('D-----------i', :chu)
  end

  def test_animacy
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('Nb-p---fd---i', :chu)
    assert_equal false, m.is_valid?('Nb-p---fd-i-i', :chu)
    assert_equal true, m.is_valid?('Nb-p---fa---i', :chu)
    assert_equal false, m.is_valid?('Nb-p---fa-i-i', :chu)
    assert_equal true, m.is_valid?('Nb-p---md---i', :chu)
    assert_equal false, m.is_valid?('Nb-p---md-i-i', :chu)

    assert_equal false, m.is_valid?('Nb-p---ma---i', :chu)
    assert_equal true, m.is_valid?('Nb-p---ma-i-i', :chu)
  end
end
