require File.dirname(__FILE__) + '/../test_helper'

class LemmaTest < ActiveSupport::TestCase
  fixtures :lemmata

  def test_by_completion
    assert_equal ["belligero", "bellum", "cedo#1"], Lemma.where(:language_tag => 'lat').by_completions(%w{apo bel ced#1}).map(&:export_form).sort
  end

  def test_merging
    a, b = Lemma.find(1000006), Lemma.find(1000007)

    assert_equal [1000007], a.mergeable_lemmata.pluck(:id)
    assert_equal [1000006], b.mergeable_lemmata.pluck(:id)

    assert a.mergeable?(b)
    assert b.mergeable?(a)

    a.merge!(b)

    a, b = Lemma.find(1000006), Lemma.find(1000005)

    assert !a.mergeable?(b)
    assert !b.mergeable?(a)

    assert_raise ArgumentError do
      a.merge!(b)
    end
  end
end
