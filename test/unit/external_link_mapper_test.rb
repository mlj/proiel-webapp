#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../test_helper'

class BiblosMapperTest < ActiveSupport::TestCase
  def test_loading
    BiblosExternalLinkMapper.instance
  end

  def test_mapping_short
    assert_equal "http://biblos.com/matthew/", BiblosExternalLinkMapper.instance.to_url("MATT")
  end

  def test_mapping_long
    assert_equal "http://biblos.com/matthew/1-1.htm", BiblosExternalLinkMapper.instance.to_url("MATT 1.1")
  end
end

class BibelenNOReferenceTest < ActiveSupport::TestCase
  def test_loading
    BiblosExternalLinkMapper.instance
  end

  def test_mapping
    assert_equal "http://bibelen.no/chapter.aspx?book=1TH&chapter=2", BibelenNOExternalLinkMapper.instance.to_url("1THESS 2.1")
  end
end
