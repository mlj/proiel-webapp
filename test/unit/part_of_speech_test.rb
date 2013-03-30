require File.dirname(__FILE__) + '/../test_helper'

class PartOfSpeechTestCase < ActiveSupport::TestCase
  def setup
    @tag1 = 'R-'
    @tag2 = 'Df'
    @m1 = PartOfSpeechTag.new(@tag1)
    @m2 = PartOfSpeechTag.new(@tag2)
  end

  def test_tag_reader
    assert_equal @tag1, @m1.part_of_speech
    assert_equal @tag2, @m2.part_of_speech
  end

  def test_to_s
    assert_equal @tag1, @m1.to_s
    assert_equal @tag2, @m2.to_s
  end

  def test_summaries
    assert_equal 'preposition', @m1.summary
    assert_equal 'adverb', @m2.summary

    assert_equal 'prep.', @m1.abbreviated_summary
    assert_equal 'adv.', @m2.abbreviated_summary
  end
end
