require File.dirname(__FILE__) + '/../test_helper'

class CitationTestCase < ActiveSupport::TestCase
  fixtures :tokens
  fixtures :sentences
  fixtures :source_divisions
  fixtures :sources

  def setup
  end

  def test_citation_strip_prefix
    citation_strip_prefix "Matt 5.16", "Matt 5.17"
    citation_strip_prefix "Matt 5.16", "Matt 5.17"
    citation_strip_prefix "Matt 5.16", "Matt 5.17"
    citation_strip_prefix "Matt 6.16", "Matt 5.17"
    citation_strip_prefix "Matt 5.17", "Matt 5"
    citation_strip_prefix "Matt 5",    "Matt 5.17"

    # Test some edge cases
    citation_strip_prefix "Matt 5.16", ""
    citation_strip_prefix "", "Matt 5.17"
  end

  def test_citation_prefix_and_suffix
    t = Token.first
    assert_equal "1.1", t.citation_part
    assert_equal "Vulg.", t.sentence.source_division.source.citation_part

    assert_equal "Vulg. 1.1", t.citation
    assert_equal "Vulg.", t.sentence.source_division.source.citation
  end
end
