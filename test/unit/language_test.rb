require File.dirname(__FILE__) + '/../test_helper'

class LanguageTestCase < ActiveSupport::TestCase
  def setup
    @tag1 = 'lat'
    @tag2 = 'grc'
    @m1 = LanguageTag.new(@tag1)
    @m2 = LanguageTag.new(@tag2)
  end

  def test_tag_reader
    assert_equal @tag1, @m1.language
    assert_equal @tag2, @m2.language
  end

  def test_to_s
    assert_equal @tag1, @m1.to_s
    assert_equal @tag2, @m2.to_s
  end
end
