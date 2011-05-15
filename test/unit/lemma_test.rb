require File.dirname(__FILE__) + '/../test_helper'

class LemmaTest < ActiveSupport::TestCase
  fixtures :lemmata

  def test_by_completion
    assert_equal ["belligero", "bellum", "cedo#1"], Lemma.by_completions('lat', %w{apo bel ced#1}).map(&:export_form).sort
  end

  def test_merging
    a, b = Lemma.find(6), Lemma.find(7)

    assert a.mergable?(b)
    assert b.mergable?(a)

    a.merge!(b)

    a, b = Lemma.find(6), Lemma.find(5)

    assert !a.mergable?(b)
    assert !b.mergable?(a)

    assert_raise ArgumentError do
      a.merge!(b)
    end
  end
end
