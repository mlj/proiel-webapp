require File.dirname(__FILE__) + '/../test_helper'

class LemmaTest < ActiveSupport::TestCase
  fixtures :lemmata

  def test_by_completion
    language = Language.find_by_tag("lat")
    l = language.lemmata
    assert_equal ["belligero", "bellum", "cedo#1"], l.by_completions(%w{apo bel ced#1}).map(&:export_form).sort
  end
end
