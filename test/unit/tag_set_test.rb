require File.dirname(__FILE__) + '/../test_helper'

class TagSetTestCase < ActiveSupport::TestCase
  def test_information_structure_tag_set_accessor
    assert TagSets.has_tag_set?(:information_structure)
    assert TagSets.has_tag_set?('information_structure')

    assert TagSets[:information_structure].is_a?(TagSet)
    assert TagSets['information_structure'].is_a?(TagSet)
  end

  def test_language_tag_set_accessor
    assert TagSets.has_tag_set?(:language)
    assert TagSets.has_tag_set?('language')

    assert TagSets[:language].is_a?(TagSet)
    assert TagSets['language'].is_a?(TagSet)
  end

  def test_language_tag_set
    assert TagSets[:language].has_tag?(:lat)
    assert TagSets[:language].has_tag?('lat')

    assert !TagSets[:language].has_tag?(:qqq)
    assert !TagSets[:language].has_tag?('qqq')

    assert_equal 'Latin', TagSets[:language][:lat]
    assert_equal 'Latin', TagSets[:language]['lat']
  end
end
