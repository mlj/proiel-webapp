require File.dirname(__FILE__) + '/../test_helper'

class BiblosExternalLinkerTest < ActiveSupport::TestCase
  def test_loading
    BiblosExternalLinkMapper.instance
  end

  def test_mapping_invalid
    assert_nil BiblosExternalLinkMapper.instance.to_url("something MATT 1.1")
  end

  def test_mapping_long
    assert_equal "http://biblehub.com/matthew/1-1.htm", BiblosExternalLinkMapper.instance.to_url("GNT MATT 1.1")
  end
end
