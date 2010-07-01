require File.dirname(__FILE__) + '/../test_helper'

class LemmaTest < ActiveSupport::TestCase
  fixtures :lemmata

  def test_by_completion
    assert_equal ["belligero", "bellum", "cedo#1"], Lemma.by_completions('lat', %w{apo bel ced#1}).map(&:export_form).sort
  end
end
