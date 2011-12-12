require File.dirname(__FILE__) + '/../test_helper'

class PresentationTestCase < ActiveSupport::TestCase
  fixtures :tokens
  fixtures :sentences

  def test_token_presentation
    t = Token.first

    assert_equal "cum", t.form

    assert_equal nil, t.presentation_before
    assert_equal ", ", t.presentation_after

    assert_equal "cum, ", t.to_s
  end

  def test_sentence_presentation
    s = Sentence.first

    assert_equal "Junky text ", s.presentation_before
    assert_equal " txet yknuJ", s.presentation_after

    assert_equal "Junky text cum, cum (cum) cum! txet yknuJ", s.to_s
  end
end
