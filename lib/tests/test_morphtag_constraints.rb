#!/usr/bin/env ruby

require 'proiel/morphtag_constraints'
require 'test/unit'

class MorphtagConstraintsTestCase < Test::Unit::TestCase
  def test_simple
    m = PROIEL::MorphtagConstraints.instance
    assert_equal true, m.is_valid?('V-3sfio-----', :la)
    assert_equal false, m.is_valid?('V-----------', :la)
    assert_equal true, m.is_valid?('A--p---fac--', :la)
    assert_equal false, m.is_valid?('D-----------', :cu)
  end
end
