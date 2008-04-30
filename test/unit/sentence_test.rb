require File.dirname(__FILE__) + '/../test_helper'

class SentenceTest < ActiveSupport::TestCase
  def setup
    @sentence = Sentence.find(1)
  end

  def test_model
    assert_kind_of Sentence, @sentence
  end
end
