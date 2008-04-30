#!/usr/bin/env ruby
#
# reference.rb - PROIEL text location reference class
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: reference.rb 416 2008-02-27 15:28:38Z mariuslj $
#

require 'yaml'
require 'singleton'

module PROIEL
  # A class that represents a reference to a particular location in the
  # text. The reference can be either punctual or an interval, and may
  # be presented either using the canonical Book, Chapter, Verse system
  # or the PROIEL Source, Book, Sentence, Word system.

  class Reference
    attr_reader :start
    attr_reader :end
    attr_reader :source
    attr_reader :book
    attr_reader :source_id
    attr_reader :book_id
    attr_reader :location

    def initialize(source, source_id, book, book_id, location = {})
      @source = source
      @source_id = source_id
      @book = book 
      @book_id = book_id

      @location = location
    end

    def classical_reference(options = {})
      "#{@book.titlecase} #{format_interval(:chapter, :verse, ':')}"
    end

    def proiel_reference
      "#{@source.titlecase} #{@book.titlecase} #{format_interval(:sentence, :word)}"
    end

    def to_s
      proiel_reference
    end

    # Creates a URL to an external text site.
    def external_url(site)
      case site
      when :biblos
        o = BiblosReferenceMapper.instance
      when :bibelen_no
        o = BibelenNOReferenceMapper.instance
      else
        raise "Unknown site #{site}"
      end
      o.to_url(self)
    end

    def verse
      get_interval(:verse).first #FIXME
    end

    private

    def format_interval(level1, level2, separator = ',')
      c = get_interval(level1)
      v = get_interval(level2)

      if v
        s = [ c[0], v[0] ].join(separator)

        if c[0] != c[1]
          s << "-#{ [ c[1], v[1] ].join(separator)}"
        elsif v[0] != v[1]
          s << "-#{v[1]}"
        end
      else
        s = c[0]
        if c[0] != c[1]
          s << "-#{c[1]}"
        end
      end

      s
    end

    def get_interval(level)
      if @location[level].is_a?(Range)
        [@location[level].first, @location[level].last]
      elsif @location[level].is_a?(NilClass)
        nil
      else
        [@location[level], @location[level]]
      end
    end
  end

  class ReferenceMapper
    include Singleton

    def initialize(file_name, base_url)
      datadir = File.expand_path(File.dirname(__FILE__))
      @mapping = YAML::load(File.open(File.join(datadir, file_name)))
      @base_url = base_url
    end
  end

  # A mapping class for references to Biblos URLs.
  class BiblosReferenceMapper < ReferenceMapper
    def initialize
      super('biblos.yml', 'http://biblos.com/')
    end

    def to_url(ref)
      # Links are on the form http://biblos.com/matthew/24-44.htm.
      r = @base_url + @mapping[ref.book] + '/'
      if ref.location
        r += "#{ref.location[:chapter]}-#{ref.verse}.htm"
      end
      r
    end
  end

  class BibelenNOReferenceMapper < ReferenceMapper
    def initialize
      super('bibelen.no.yml', 'http://bibelen.no/')
    end

    def to_url(ref)
      # Links are on the form chapter.aspx?book=BOOK&chapter=CHAPTER 
      r = @base_url + 'chapter.aspx?book=' + @mapping[ref.book]
      if ref.location
        r += "&chapter=#{ref.location[:chapter]}"
      end
      r
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  include PROIEL

  class BiblosReferenceTest < Test::Unit::TestCase
    def test_loading
      BiblosReferenceMapper.instance  
    end
    
    def test_mapping_short
      r = Reference.new(1, 'vulgate', 2, 'MATT')
      assert_equal "http://biblos.com/matthew/", BiblosReferenceMapper.instance.to_url(r)
    end

    def test_mapping_long
      r = Reference.new(1, 'vulgate', 2, 'MATT', { :chapter => 1, :verse => 1 })
      assert_equal "http://biblos.com/matthew/1-1.htm", BiblosReferenceMapper.instance.to_url(r)
    end
  end

  class BibelenNOReferenceTest < Test::Unit::TestCase
    def test_loading
      BiblosReferenceMapper.instance  
    end
    
    def test_mapping
      r = Reference.new(1, 'vulgate', 2, '1THESS', { :chapter => 2 })
      assert_equal "http://bibelen.no/chapter.aspx?book=1TH&chapter=2", BibelenNOReferenceMapper.instance.to_url(r)
    end
  end
end
