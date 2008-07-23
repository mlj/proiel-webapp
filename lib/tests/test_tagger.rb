#!/usr/bin/env ruby

require 'test/unit'
require 'proiel/tagger'

class TaggerTagTestCase < Test::Unit::TestCase
  include PROIEL

  TEST_CONFIG_FILE = File.join(File.dirname(__FILE__), 'test_tagger.yml')
  TEST_DEFAULT_OPTIONS = {
    :data_directory => File.join(File.dirname(__FILE__), '..', 'morphology')
  }

  def test_loading
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
  end

  def test_unambiguous
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:unambiguous, MorphLemmaTag.new("C:et"), [MorphLemmaTag.new("C:et"), 1.0]], tagger.tag_token(:la, 'et')
  end

  def test_instance_frequency
    # With this setup the G occurs more often than R in the data and
    # should be preferred
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS.merge({ :statistics_retriever => lambda { |language, form| [[ "R----------", "cum", 20 ], [ "G----------", "cum", 80 ]] }}))
    assert_equal [:ambiguous, MorphLemmaTag.new("G:cum"), 
      [MorphLemmaTag.new("G:cum"), 1.4], 
      [MorphLemmaTag.new("R:cum"), 1.1],
      [MorphLemmaTag.new("Dq:cum"), 1.0]], tagger.tag_token(:la, 'cum')

    # Then do it the other way around
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS.merge({:statistics_retriever => lambda { |language, form| [[ "R----------", "cum", 300 ], [ "G----------", "cum", 100 ]] }}))
    assert_equal [:ambiguous, MorphLemmaTag.new("R:cum"), 
      [MorphLemmaTag.new("R:cum"), 1.375], 
      [MorphLemmaTag.new("G:cum"), 1.125],
      [MorphLemmaTag.new("Dq:cum"), 1.0]], tagger.tag_token(:la, 'cum')
  end

  def test_source_tag_influence
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete
    assert_equal [:ambiguous, MorphLemmaTag.new("R:cum"), 
      [MorphLemmaTag.new("R:cum"), 1.0], 
      [MorphLemmaTag.new("G:cum"), 0.5],
      [MorphLemmaTag.new("Dq:cum"), 0.5],
    ], tagger.tag_token(:la, 'cum', MorphLemmaTag.new('R:cum'))

    assert_equal [:ambiguous, MorphLemmaTag.new("G:cum"), 
      [MorphLemmaTag.new("G:cum"), 1.0], 
      [MorphLemmaTag.new("Dq:cum"), 0.5],
      [MorphLemmaTag.new("R:cum"), 0.5],
    ], tagger.tag_token(:la, 'cum', MorphLemmaTag.new('G:cum'))
  end

  def test_existing_tag_influence_incomplete_tag
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is incomplete
    assert_equal [:ambiguous, MorphLemmaTag.new("Dn:ne"),
      [MorphLemmaTag.new("Dn:ne"), 1.0], 
      [MorphLemmaTag.new("G:ne"), 0.5], 
      [MorphLemmaTag.new("I:ne"), 0.5],
    ], tagger.tag_token(:la, 'ne', MorphLemmaTag.new('D'))
  end

  def test_existing_tag_influence_complete_tag_but_contradictory_lemma
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete, but contradictory lemma 
    assert_equal [:ambiguous, nil,
      [MorphLemmaTag.new("Dn:ne"), 0.5], 
      [MorphLemmaTag.new("G:ne"), 0.5],
      [MorphLemmaTag.new("I:ne"), 0.5], 
    ], tagger.tag_token(:la, 'ne', MorphLemmaTag.new('Df:neo'))
  end

  def test_draw
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, nil, 
      [MorphLemmaTag.new("Dq:cum"), 1.0],
      [MorphLemmaTag.new("G:cum"), 1.0],
      [MorphLemmaTag.new("R:cum"), 1.0],
    ], tagger.tag_token(:la, 'cum')
  end

  def test_generated_lookup
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, nil, 
      [MorphLemmaTag.new("Ne-p---mv:Herodes"), 0.2],
      [MorphLemmaTag.new("Ne-s---mn:Herodes"), 0.2],
      [MorphLemmaTag.new("Ne-p---ma:Herodes"), 0.2],
      [MorphLemmaTag.new("Ne-p---mn:Herodes"), 0.2],
    ], tagger.tag_token(:la, 'Herodes')
  end

  def test_failed_tagging
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:failed, nil], tagger.tag_token(:la, 'fjotleik')
  end

  def test_sfst_lookup
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, nil, 
      [MorphLemmaTag.new("Nb-p---fg:ioka"), 0.2],
    ], tagger.tag_token(:cu, 'отецъ')
  end
end
