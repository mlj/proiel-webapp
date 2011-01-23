require File.dirname(__FILE__) + '/../test_helper'

class CitationTestCase < ActiveSupport::TestCase
  fixtures :tokens
  fixtures :sentences
  fixtures :source_divisions
  fixtures :sources

  def setup
  end

  def test_citation_prefix_and_suffix
    t = Token.first
    assert_equal "1.1", t.citation_part
    assert_equal "Vulg.", t.sentence.source_division.source.citation_part

    assert_equal "Vulg. 1.1", t.citation
    assert_equal "Vulg.", t.sentence.source_division.source.citation
  end
end
