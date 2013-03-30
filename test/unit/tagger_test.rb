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
  fixtures :inflections

  def setup
    @amen_fs = MorphFeatures.new("amen,I-,lat", "---------n")
    @cum_c_fs = MorphFeatures.new("cum,C-,lat", "---------n")
    @cum_r_fs = MorphFeatures.new("cum,R-,lat", "---------n")
    @cum_dq_fs = MorphFeatures.new("cum,Dq,lat", "---------n")
    @ne_c_fs = MorphFeatures.new("ne,C-,lat", "---------n")
    @ne_i_fs = MorphFeatures.new("ne,I-,lat", "---------n")
    @ne_df_fs = MorphFeatures.new("ne,Df,lat", "---------n")
    @neo_df_fs = MorphFeatures.new("neo,Df,lat", "---------n")
  end

  def test_loading
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
  end

  def test_unambiguous
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:unambiguous, @amen_fs, [@amen_fs, 1.0]], tagger.tag_token(:lat, 'amen')
  end

  def test_instance_frequency
    # With this setup the G occurs more often than R in the data and
    # should be preferred
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:ambiguous, @cum_c_fs,
      [@cum_c_fs, 1.0 + 0.75 * 0.5], [@cum_r_fs, 1.0 + 0.25 * 0.5], [@cum_dq_fs, 1.0 + 0.00 * 0.5]
    ], tagger.tag_token(:lat, 'cum')
  end

  def test_source_tag_influence
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete
    assert_equal [:ambiguous, @cum_r_fs,
      [@cum_r_fs, (1.0 + 0.25 * 0.5) * 1.0], [@cum_c_fs, (1.0 + 0.75 * 0.5) * 0.5], [@cum_dq_fs, (1.0)              * 0.5],
    ], tagger.tag_token(:lat, 'cum', @cum_r_fs)

    assert_equal [:ambiguous, @cum_c_fs,
      [@cum_c_fs, (1.0 + 0.75 * 0.5) * 1.0], [@cum_r_fs, (1.0 + 0.25 * 0.5) * 0.5], [@cum_dq_fs, (1.0)              * 0.5],
    ], tagger.tag_token(:lat, 'cum', @cum_c_fs)
  end

  def test_existing_tag_influence_incomplete_tag
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    incomplete_d_fs = MorphFeatures.new(",Df,lat", nil)

    # Existing tag is incomplete
    assert_equal [:ambiguous, @ne_df_fs,
      [@ne_df_fs, 1.0], [@ne_i_fs, 0.5], [@ne_c_fs, 0.5],
    ], tagger.tag_token(:lat, 'ne', incomplete_d_fs)
  end

  def test_existing_tag_influence_complete_tag_but_contradictory_lemma
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)

    # Existing tag is complete, but contradictory lemma
    assert_equal [:ambiguous, nil,
      [@ne_i_fs, 0.5], [@ne_df_fs, 0.5], [@ne_c_fs, 0.5],
    ], tagger.tag_token(:lat, 'ne', @neo_df_fs)
  end

  def test_failed_tagging
    tagger = Tagger::Tagger.new(TEST_CONFIG_FILE, TEST_DEFAULT_OPTIONS)
    assert_equal [:failed, nil], tagger.tag_token(:lat, 'fjotleik', :text)
  end
end
