require File.dirname(__FILE__) + '/../test_helper'

TEST_CONFIG_FILE = File.join(File.dirname(__FILE__), 'tagger_test.yml')
TEST_DEFAULT_OPTIONS = {
  :data_directory => File.join(File.dirname(__FILE__), '..', '..', 'lib', 'morphology'),
  :logger => nil,
}

# Not really a test of a model, but close enough.
class TaggerTest < ActiveSupport::TestCase
  fixtures :sources
  fixtures :sentences
  fixtures :tokens
  fixtures :languages

  def test_loading
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
  end

  def test_unambiguous
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:unambiguous, PROIEL::MorphLemmaTag.new("I-----------n:amen"), [PROIEL::MorphLemmaTag.new("I-----------n:amen"), 1.0]], tagger.tag_token(:lat, 'amen')
  end

  def test_instance_frequency
    # With this setup the G occurs more often than R in the data and
    # should be preferred
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("C-----------n:cum"),
      [PROIEL::MorphLemmaTag.new("C-----------n:cum"), 1.0 + 0.75 * 0.5],
      [PROIEL::MorphLemmaTag.new("R-----------n:cum"), 1.0 + 0.25 * 0.5],
      [PROIEL::MorphLemmaTag.new("Dq----------n:cum"), 1.0 + 0.00 * 0.5]], tagger.tag_token(:lat, 'cum')
  end

  def test_source_tag_influence
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete
    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("R-----------n:cum"),
      [PROIEL::MorphLemmaTag.new("R-----------n:cum"), (1.0 + 0.25 * 0.5) * 1.0],
      [PROIEL::MorphLemmaTag.new("C-----------n:cum"), (1.0 + 0.75 * 0.5) * 0.5],
      [PROIEL::MorphLemmaTag.new("Dq----------n:cum"), (1.0)              * 0.5],
    ], tagger.tag_token(:lat, 'cum', PROIEL::MorphLemmaTag.new('R-----------n:cum'))

    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("C-----------n:cum"),
      [PROIEL::MorphLemmaTag.new("C-----------n:cum"), (1.0 + 0.75 * 0.5) * 1.0],
      [PROIEL::MorphLemmaTag.new("R-----------n:cum"), (1.0 + 0.25 * 0.5) * 0.5],
      [PROIEL::MorphLemmaTag.new("Dq----------n:cum"), (1.0)              * 0.5],
    ], tagger.tag_token(:lat, 'cum', PROIEL::MorphLemmaTag.new('C-----------n:cum'))
  end

  def test_existing_tag_influence_incomplete_tag
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is incomplete
    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("Df----------n:ne"),
      [PROIEL::MorphLemmaTag.new("Df----------n:ne"), 1.0],
      [PROIEL::MorphLemmaTag.new("I-----------n:ne"), 0.5],
      [PROIEL::MorphLemmaTag.new("C-----------n:ne"), 0.5],
    ], tagger.tag_token(:lat, 'ne', PROIEL::MorphLemmaTag.new('D'))
  end

  def test_existing_tag_influence_complete_tag_but_contradictory_lemma
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete, but contradictory lemma
    assert_equal [:ambiguous, nil,
      [PROIEL::MorphLemmaTag.new("Df----------n:ne"), 0.5],
      [PROIEL::MorphLemmaTag.new("I-----------n:ne"), 0.5],
      [PROIEL::MorphLemmaTag.new("C-----------n:ne"), 0.5],
    ], tagger.tag_token(:lat, 'ne', PROIEL::MorphLemmaTag.new('Df----------n:neo'))
  end

  def test_failed_tagging
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:failed, nil], tagger.tag_token(:lat, 'fjotleik', :text)
  end

  def test_sfst_lookup
#    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
#    assert_equal [:ambiguous, nil,
#      [PROIEL::MorphLemmaTag.new("Nb-p---fg:ioka"), 0.2],
#    ], tagger.tag_token(:cu, 'отецъ')
  end
end
