require File.dirname(__FILE__) + '/../test_helper'

class PresentationTestCase < ActiveSupport::TestCase
  fixtures :tokens
  fixtures :sentences

  def setup
  end

  def test_token_presentation_stream
    t = Token.first
    assert_equal [[:w, "cum"], [:pc, ", "]], t.presentation_stream
  end

  def test_token_presentation
    t = Token.first
    assert_equal "cum", t.form
    assert_equal nil, t.presentation_before
    assert_equal ", ", t.presentation_after

    assert_equal "cum", t.to_s
    assert_equal "cum", t.to_s(:text_only)
    assert_equal "cum, ", t.to_s(:text_and_presentation)
    assert_equal "<w>cum</w><pc>, </pc>", t.to_s(:text_and_presentation_with_markup)
  end

  def test_sentence_presentation_stream
    s = Sentence.first
    assert_equal [
      [:pc, 'Junky text '],
      [:w, 'cum'],
      [:pc, ', '],
      [:w, 'cum'], 
      [:s, ' '],
      [:pc, '('],
      [:w, 'cum'],
      [:pc, ') '],
      [:w, 'cum'],
      [:pc, '!'],
      [:pc, ' txet yknuJ']
    ], s.presentation_stream
  end

  def test_sentence_presentation
    s = Sentence.first
    assert_equal "Junky text ", s.presentation_before
    assert_equal " txet yknuJ", s.presentation_after

    assert_equal "Junky text cum, cum (cum) cum! txet yknuJ", s.to_s
    assert_equal "cum cum cum cum", s.to_s(:text_only)
    assert_equal "Junky text cum, cum (cum) cum! txet yknuJ", s.to_s(:text_and_presentation)
    assert_equal "<pc>Junky text </pc><w>cum</w><pc>, </pc><w>cum</w><s> </s><pc>(</pc><w>cum</w><pc>) </pc><w>cum</w><pc>!</pc><pc> txet yknuJ</pc>", s.to_s(:text_and_presentation_with_markup)
  end

  def test_diff_presentation_stream
    original = [[:pc, 'PREFIX '],
      [:pc, '('], [:w, 'forty'], [:pc, ' '], [:w, 'two'], [:pc, ') '],
      [:w, 'thousand'], [:pc, '!'],
      [:pc, ' SUFFIX']]

    # An valid diff: tokens merged across whitespace
    valid_new = [[:pc, 'PREFIX '],
      [:pc, '('], [:w, 'forty two'], [:pc, ') '],
      [:w, 'thousand'], [:pc, '!'],
      [:pc, ' SUFFIX']]

    # An invalid diff: contents altered
    invalid_new1 = [[:pc, 'PREFIX '],
      [:pc, '('], [:w, 'forty three'], [:pc, ') '],
      [:w, 'thousand'], [:pc, '!'],
      [:pc, ' SUFFIX']]

    # An invalid diff: contents missing
    invalid_new2 = [[:pc, 'PREFIX '],
      [:pc, '('], [:w, 'forty two'],
      [:w, 'thousand'], [:pc, '!'],
      [:pc, ' SUFFIX']]

    # An invalid diff: tokens merged across punctuation
    invalid_new3 = [[:pc, 'PREFIX '],
      [:pc, '('], [:w, 'forty'], [:pc, ' '], [:w, 'two) thousand'],
      [:pc, '!'],
      [:pc, ' SUFFIX']]

    assert_equal [
      [[:pc, "PREFIX "], [:pc, "PREFIX "]],
      [[:pc, "("],       [:pc, "("]],
      [[:w, "forty"],    [:w, "forty two"]],
      [[:pc, " "],       nil],
      [[:w, "two"],      nil],
      [[:pc, ") "],      [:pc, ") "]],
      [[:w, "thousand"], [:w, "thousand"]],
      [[:pc, "!"],       [:pc, "!"]],
      [[:pc, " SUFFIX"], [:pc, " SUFFIX"]]
    ], Sentence.diff_presentation_stream(original, valid_new)

    assert_equal [
      [[:pc, "PREFIX "],  [:pc, "PREFIX "]],
      [[:pc, "("],        [:pc, "("]],
      [[:w, "forty two"], [:w, "forty"]],
      [nil,               [:pc, " "]],
      [nil,               [:w, "two"]],
      [[:pc, ") "],       [:pc, ") "]],
      [[:w, "thousand"],  [:w, "thousand"]],
      [[:pc, "!"],        [:pc, "!"]],
      [[:pc, " SUFFIX"],  [:pc, " SUFFIX"]]
    ], Sentence.diff_presentation_stream(valid_new, original)

    assert_raises ArgumentError do
      Sentence.diff_presentation_stream(original, invalid_new1)
    end

    assert_raises ArgumentError do
      Sentence.diff_presentation_stream(original, invalid_new2)
    end

    #assert_raises ArgumentError do
    #  Sentence.diff_presentation_stream(original, invalid_new3)
    #end
  end

  def test_parse_presentation_markup
    assert_equal [
          [:pc, 'Junky text '],
          [:w, 'cum'],
          [:pc, ', '],
          [:w, 'cum'], 
          [:s, ' '],
          [:pc, '('],
          [:w, 'cum'],
          [:pc, ') '],
          [:w, 'cum'],
          [:pc, '!'],
          [:pc, ' txet yknuJ']
        ], Sentence.parse_presentation_markup("<pc>Junky text </pc><w>cum</w><pc>, </pc><w>cum</w><s> </s><pc>(</pc><w>cum</w><pc>) </pc><w>cum</w><pc>!</pc><pc> txet yknuJ</pc>")
  end
end
