require "spec_helper"

describe Lemma do
  it "has a valid factory" do
    FactoryGirl.create(:lemma).should be_valid
  end

  it "returns all represented languages" do
    languages = %w(lat grc chu)

    languages.each do |l|
      FactoryGirl.create(:lemma, language_tag: l)
    end

    language_tags = languages.map { |l| LanguageTag.new(l) }

    Lemma.represented_languages.sort_by(&:tag).should == language_tags.sort_by(&:tag)
  end

  it "returns all represented languages in correct order" do
    languages = %w(lat grc chu)

    languages.each do |l|
      FactoryGirl.create(:lemma, language_tag: l)
    end

    language_tags = languages.map { |l| LanguageTag.new(l) }

    Lemma.represented_languages.should == language_tags.sort_by(&:to_label)
  end

  it "returns all represented parts of speech" do
    parts_of_speech = %w(V- Df Nb)

    parts_of_speech.each do |p|
      FactoryGirl.create(:lemma, part_of_speech_tag: p)
    end

    part_of_speech_tags = parts_of_speech.map { |p| PartOfSpeech.new(p) }

    Lemma.represented_parts_of_speech.sort_by(&:tag).should == part_of_speech_tags.sort_by(&:tag)
  end

  it "returns all represented parts of speech in correct order" do
    parts_of_speech = %w(V- Df Nb)

    parts_of_speech.each do |p|
      FactoryGirl.create(:lemma, part_of_speech_tag: p)
    end

    part_of_speech_tags = parts_of_speech.map { |p| PartOfSpeech.new(p) }

    Lemma.represented_parts_of_speech.should == part_of_speech_tags.sort_by(&:to_label)
  end
end
