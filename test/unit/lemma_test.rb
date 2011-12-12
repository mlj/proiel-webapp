require File.dirname(__FILE__) + '/../test_helper'

class LemmaTest < ActiveSupport::TestCase
  fixtures :lemmata

  def test_by_completion
    assert_equal ["belligero", "bellum", "cedo#1"], Lemma.where(:language_tag => 'lat').by_completions(%w{apo bel ced#1}).map(&:export_form).sort
  end

  def test_merging
    a, b = Lemma.find(6), Lemma.find(7)

    assert_equal [7], a.mergeable_lemmata.pluck(:id)
    assert_equal [6], b.mergeable_lemmata.pluck(:id)

    assert a.mergeable?(b)
    assert b.mergeable?(a)

    a.merge!(b)

    a, b = Lemma.find(6), Lemma.find(5)

    assert !a.mergeable?(b)
    assert !b.mergeable?(a)

    assert_raise ArgumentError do
      a.merge!(b)
    end
  end
end
