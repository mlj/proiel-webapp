require File.dirname(__FILE__) + '/../test_helper'

class CitationTestCase < ActiveSupport::TestCase
  fixtures :tokens
  fixtures :sentences
  fixtures :source_divisions
  fixtures :sources

  def setup
  end

  def test_citation
    t = Token.first

    assert_equal "1.1", t.citation_part
    assert_equal "Vulg.", t.sentence.source_division.source.citation_part

    assert_equal "Vulg. 1.1", t.citation
    assert_equal "1.1", t.citation_without_source

    assert_equal "Vulg. 1.1–4", t.sentence.citation
    assert_equal "1.1–4", t.sentence.citation_without_source

    assert_equal "Vulg. 1.1–3.2", t.sentence.source_division.citation
    assert_equal "1.1–3.2", t.sentence.source_division.citation_without_source

    assert_equal "Vulg.", t.sentence.source_division.source.citation
  end

  def test_citation_when_citation_part_empty_string_or_nil
    s = Sentence.first
    t = s.tokens.new(citation_part: '')

    assert_equal 'Vulg.', t.citation
    assert_equal nil, t.citation_without_source

    #assert_equal 'Vulg. 1.1–4', s.citation
    #assert_equal '1.1–4', s.citation_without_source

    t = s.tokens.new(citation_part: nil)

    assert_equal 'Vulg.', t.citation
    assert_equal nil, t.citation_without_source

    #assert_equal 'Vulg. 1.1–4', t.sentence.citation
    #assert_equal '1.1–4', t.sentence.citation_without_source
  end

  def test_citation_with_empty_sentence
    s = Sentence.find(100)

    assert_equal 0, s.tokens.length
    assert_equal "Pl. Am.", s.citation
    assert_equal nil, s.citation_without_source
    assert_equal "Pl. Am.", s.source_division.citation
    assert_equal nil, s.source_division.citation_without_source
  end

  def test_citation_with_empty_source_division
    s = SourceDivision.find(101)

    assert_equal 0, s.sentences.length
    assert_equal "Pl. Am.", s.citation
    assert_equal nil, s.citation_without_source
  end
end
