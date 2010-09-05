require File.dirname(__FILE__) + '/../test_helper'

class MorphtagConstraintsTestCase < ActiveSupport::TestCase
  def test_simple
    m = MorphtagConstraints.instance
    assert_equal true, m.is_valid?('V-3sfip----i', :lat)
    assert_equal false, m.is_valid?('V----------i', :lat)
    assert_equal true, m.is_valid?('A--p---fac-i', :lat)
    assert_equal false, m.is_valid?('D--------i', :chu)
  end
end
