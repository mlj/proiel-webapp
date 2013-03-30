require File.dirname(__FILE__) + '/../test_helper'

class TagSetTestCase < ActiveSupport::TestCase
  def test_information_structure_tag_set_accessor
    assert InformationStatusTag.new('new').is_a?(TagObject)
  end

  def test_language_tag_set_accessor
    assert LanguageTag.new('lat').is_a?(TagObject)
  end

  def test_part_of_speech_tag_set_accessor
    assert PartOfSpeechTag.new('Df').is_a?(TagObject)
  end

  def test_language_tag_lookup
    assert LanguageTag.include?(:lat)
    assert LanguageTag.include?('lat')

    assert !LanguageTag.include?(:qqq)
    assert !LanguageTag.include?('qqq')

    assert LanguageTag.find('lat')
    assert LanguageTag.find(:lat)
    assert LanguageTag[:lat]
    assert LanguageTag['lat']
  end

  def test_language_tag_comparison
    @lat = LanguageTag.find('lat')
    @got = LanguageTag.find('got')

    assert (@lat != @got)
    assert (@lat > @got)
  end

  def test_language_tag_access
    @lat = LanguageTag.find('lat')
    @got = LanguageTag.find('got')

    assert 'Latin', @lat.name
    assert 'Gothic', @got.name
  end
end
