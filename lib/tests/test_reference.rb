#!/usr/bin/env ruby
require 'test/unit'
require 'proiel/reference'
include PROIEL

class BiblosReferenceTest < Test::Unit::TestCase
  def test_loading
    BiblosReferenceMapper.instance  
  end
  
  def test_mapping_short
    r = Reference.new('vulgate', 1, 'MATT', 2)
    assert_equal "http://biblos.com/matthew/", BiblosReferenceMapper.instance.to_url(r)
  end

  def test_mapping_long
    r = Reference.new('vulgate', 1, 'MATT', 2, { :chapter => 1, :verse => 1 })
    assert_equal "http://biblos.com/matthew/1-1.htm", BiblosReferenceMapper.instance.to_url(r)
  end
end

class BibelenNOReferenceTest < Test::Unit::TestCase
  def test_loading
    BiblosReferenceMapper.instance  
  end
  
  def test_mapping
    r = Reference.new('vulgate', 1, '1THESS', 2, { :chapter => 2 })
    assert_equal "http://bibelen.no/chapter.aspx?book=1TH&chapter=2", BibelenNOReferenceMapper.instance.to_url(r)
  end
end
