require File.dirname(__FILE__) + '/../test_helper'

TEST_CONFIG_FILE = File.join(File.dirname(__FILE__), 'tagger_test.yml')
TEST_DEFAULT_OPTIONS = {
  :data_directory => File.join(File.dirname(__FILE__), '..', '..', 'lib', 'morphology'),
  :logger => nil # If you want to test logging: Log4r::Logger.new('dummy_test_logger').tap { |t| t.add(Log4r::Outputter.stdout) },
}

# Not really a test of a model, but close enough.
class TaggerTest < ActiveSupport::TestCase
  fixtures :sources
  fixtures :sentences
  fixtures :tokens

  def test_loading
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
  end

  def test_unambiguous
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:unambiguous, PROIEL::MorphLemmaTag.new("I:amen"), [PROIEL::MorphLemmaTag.new("I:amen"), 1.0]], tagger.tag_token(:la, 'amen')
  end

  def test_instance_frequency
    # With this setup the G occurs more often than R in the data and
    # should be preferred
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("G:cum"),
      [PROIEL::MorphLemmaTag.new("G:cum"),  1.0 + 0.75 * 0.5],
      [PROIEL::MorphLemmaTag.new("R:cum"),  1.0 + 0.25 * 0.5],
      [PROIEL::MorphLemmaTag.new("Dq:cum"), 1.0 + 0.00 * 0.5]], tagger.tag_token(:la, 'cum')
  end

  def test_source_tag_influence
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete
    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("R:cum"),
      [PROIEL::MorphLemmaTag.new("R:cum"),  (1.0 + 0.25 * 0.5) * 1.0],
      [PROIEL::MorphLemmaTag.new("G:cum"),  (1.0 + 0.75 * 0.5) * 0.5],
      [PROIEL::MorphLemmaTag.new("Dq:cum"), (1.0)              * 0.5],
    ], tagger.tag_token(:la, 'cum', PROIEL::MorphLemmaTag.new('R:cum'))

    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("G:cum"),
      [PROIEL::MorphLemmaTag.new("G:cum"),  (1.0 + 0.75 * 0.5) * 1.0],
      [PROIEL::MorphLemmaTag.new("R:cum"),  (1.0 + 0.25 * 0.5) * 0.5],
      [PROIEL::MorphLemmaTag.new("Dq:cum"), (1.0)              * 0.5],
    ], tagger.tag_token(:la, 'cum', PROIEL::MorphLemmaTag.new('G:cum'))
  end

  def test_existing_tag_influence_incomplete_tag
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is incomplete
    assert_equal [:ambiguous, PROIEL::MorphLemmaTag.new("Dn:ne"),
      [PROIEL::MorphLemmaTag.new("Dn:ne"), 1.0],
      [PROIEL::MorphLemmaTag.new("G:ne"), 0.5],
      [PROIEL::MorphLemmaTag.new("I:ne"), 0.5],
    ], tagger.tag_token(:la, 'ne', PROIEL::MorphLemmaTag.new('D'))
  end

  def test_existing_tag_influence_complete_tag_but_contradictory_lemma
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete, but contradictory lemma
    assert_equal [:ambiguous, nil,
      [PROIEL::MorphLemmaTag.new("Dn:ne"), 0.5],
      [PROIEL::MorphLemmaTag.new("G:ne"), 0.5],
      [PROIEL::MorphLemmaTag.new("I:ne"), 0.5],
    ], tagger.tag_token(:la, 'ne', PROIEL::MorphLemmaTag.new('Df:neo'))
  end

  def test_generated_lookup
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, nil,
      [PROIEL::MorphLemmaTag.new("Ne-p---mv:Herodes"), 0.2],
      [PROIEL::MorphLemmaTag.new("Ne-s---mn:Herodes"), 0.2],
      [PROIEL::MorphLemmaTag.new("Ne-p---ma:Herodes"), 0.2],
      [PROIEL::MorphLemmaTag.new("Ne-p---mn:Herodes"), 0.2],
    ], tagger.tag_token(:la, 'Herodes')
  end

  def test_failed_tagging
    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:failed, nil], tagger.tag_token(:la, 'fjotleik', :text)
  end

  def test_sfst_lookup
#    tagger = PROIEL::Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
#    assert_equal [:ambiguous, nil,
#      [PROIEL::MorphLemmaTag.new("Nb-p---fg:ioka"), 0.2],
#    ], tagger.tag_token(:cu, 'отецъ')
  end
end
