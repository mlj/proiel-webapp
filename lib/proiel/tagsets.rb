#!/usr/bin/env ruby
#
# tagsets.rb - PROIEL tag sets
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: tagsets.rb 273 2008-01-31 13:04:37Z mariuslj $
#
require 'lingua/tagset'
require 'yaml'

module PROIEL
  DATADIR = File.expand_path(File.dirname(__FILE__))

  MORPHOLOGY = Lingua::PositionalTagSet.new(File.join(DATADIR, 'morphology.xml')).freeze
  RELATIONS = Lingua::TagSet.new(File.join(DATADIR, 'relations.xml')).freeze

  INFERENCES = YAML::load_file(File.join(DATADIR, 'inferences.yml')).freeze
end

if $0 == __FILE__
  require 'test/unit'
  include PROIEL

  class RelationsTestCase < Test::Unit::TestCase
    def test_name
      assert_equal 'subject', RELATIONS[:sub].summary
    end
  end

  class MorphologyTestCase < Test::Unit::TestCase
    def test_components
      assert_equal [:major, :minor, :person, :number, :tense, :mood, :voice, :gender, :case, :degree, :animacy, :strength], MORPHOLOGY.fields
    end
  end
end
