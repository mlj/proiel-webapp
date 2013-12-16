require "spec_helper"

describe Lemma do
  it "has a valid factory" do
    FactoryGirl.create(:lemma).should be_valid
  end

  it "is invalid without a language tag" do
    FactoryGirl.build(:lemma, language_tag: nil).should_not be_valid
  end

  it "is invalid if language tag is bogus" do
    FactoryGirl.build(:lemma, language_tag: 'XXX').should_not be_valid
  end

  it "is invalid without a part of speech tag" do
    FactoryGirl.build(:lemma, part_of_speech_tag: nil).should_not be_valid
  end

  it "is invalid if part of speech tag is bogus" do
    FactoryGirl.build(:lemma, part_of_speech_tag: 'XX').should_not be_valid
  end

  it "is invalid without a lemma" do
    FactoryGirl.build(:lemma, lemma: nil).should_not be_valid
  end

  it "is valid if the variant number is an integer" do
    FactoryGirl.build(:lemma, variant: 0).should be_valid
    FactoryGirl.build(:lemma, variant: 1).should be_valid
    FactoryGirl.build(:lemma, variant: -1).should be_valid
    FactoryGirl.build(:lemma, variant: 1234567890).should be_valid
    FactoryGirl.build(:lemma, variant: '1').should be_valid
    FactoryGirl.build(:lemma, variant: '0').should be_valid
  end

# FIXME? We can really test this because Active Record's connection adapter
# will coerce the value of an integer column to an integer or nil.
#  it "is invalid if the variant number is not an integer, nil or a blank string" do
#    FactoryGirl.build(:lemma, variant: 'foobar').should_not be_valid
#    FactoryGirl.build(:lemma, variant: Hash.new).should_not be_valid
#    FactoryGirl.build(:lemma, variant: :foobar).should_not be_valid
#  end

  it "returns a language tag and a language object" do
    lemma = FactoryGirl.create(:lemma)
    lemma.language_tag.should eq 'lat'
    lemma.language.should eq LanguageTag.new('lat')
    # FIXME: ideally these objects should also be identical
    #lemma.language.should be LanguageTag.new('lat')
  end

  it "returns a part of speech tag and a part of speech object" do
    lemma = FactoryGirl.create(:lemma)
    lemma.part_of_speech_tag.should eq 'V-'
    lemma.part_of_speech.should eq PartOfSpeechTag.new('V-')
    # FIXME: ideally these objects should also be identical
    #lemma.part_of_speech.should be PartOfSpeechTag.new('V-')
  end

  it "returns a part of speech tag and a part of speech object" do
    lemma = FactoryGirl.create(:lemma)
    lemma.lemma.should eq 'sum'
  end

  it "returns all represented languages" do
    languages = %w(lat grc chu)

    languages.each do |l|
      FactoryGirl.create(:lemma, language_tag: l)
    end

    language_tags = languages.map { |l| LanguageTag.new(l) }

    Lemma.represented_languages.sort_by(&:tag).should eq language_tags.sort_by(&:tag)
  end

  it "returns all represented languages in correct order" do
    languages = %w(lat grc chu)

    languages.each do |l|
      FactoryGirl.create(:lemma, language_tag: l)
    end

    language_tags = languages.map { |l| LanguageTag.new(l) }

    Lemma.represented_languages.should eq language_tags.sort_by(&:to_label)
  end

  it "returns all represented parts of speech" do
    parts_of_speech = %w(C- V- Df Nb Ne R-)

    parts_of_speech.each do |p|
      FactoryGirl.create(:lemma, part_of_speech_tag: p)
    end

    part_of_speech_tags = parts_of_speech.map { |p| PartOfSpeechTag.new(p) }

    Lemma.represented_parts_of_speech.sort_by(&:tag).should eq part_of_speech_tags.sort_by(&:tag)
  end

  it "returns all represented parts of speech in correct order" do
    parts_of_speech = %w(C- V- Df Nb Ne R-)

    parts_of_speech.each do |p|
      FactoryGirl.create(:lemma, part_of_speech_tag: p)
    end

    part_of_speech_tags = parts_of_speech.map { |p| PartOfSpeech.new(p) }

    Lemma.represented_parts_of_speech.should eq part_of_speech_tags.sort_by(&:to_label)
  end

  describe '#possible_completions' do
    it "returns completions given a prefix" do
      FactoryGirl.create(:lemma, lemma: 'diligo')
      FactoryGirl.create(:lemma, lemma: 'dirigo')
      FactoryGirl.create(:lemma, lemma: 'credo')
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 1)
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 2)

      Lemma.
        possible_completions('lat', 'dir').
        map(&:export_form).
        sort.
        should eq %w(dirigo)
    end

    it "returns completions given multiple prefixes" do
      FactoryGirl.create(:lemma, lemma: 'diligo')
      FactoryGirl.create(:lemma, lemma: 'dirigo')
      FactoryGirl.create(:lemma, lemma: 'credo')
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 1)
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 2)

      Lemma.
        possible_completions('lat', %w{apo dir cred}).
        map(&:export_form).
        sort.
        should eq %w(credo credo#1 credo#2 dirigo)
    end

    it "respects a variant number when provided" do
      FactoryGirl.create(:lemma, lemma: 'credo')
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 1)
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 2)

      Lemma.
        possible_completions('lat', %w{cred#1}).
        map(&:export_form).
        sort.
        should eq %w(credo#1)
    end

    it "applies a restriction only on prefixes with a variant number" do
      FactoryGirl.create(:lemma, lemma: 'dirigo')
      FactoryGirl.create(:lemma, lemma: 'credo')
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 1)
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 2)

      Lemma.
        possible_completions('lat', %w{dir cred#1}).
        map(&:export_form).
        sort.
        should eq %w(credo#1 dirigo)
    end

    it "ignores a blank variant number" do
      FactoryGirl.create(:lemma, lemma: 'credo')
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 1)
      FactoryGirl.create(:lemma, lemma: 'credo', variant: 2)

      Lemma.
        possible_completions('lat', 'cred#').
        map(&:export_form).
        sort.
        should eq %w(credo credo#1 credo#2)
    end
  end

  it "is mergeable if other lemmata have the same lemma, language tag and part of speech tag" do
    l1 = FactoryGirl.create(:lemma, variant: 1)
    l2 = FactoryGirl.create(:lemma, variant: 2)

    l1.mergeable?(l2).should be_true
    l2.mergeable?(l1).should be_true
  end

  it "is not mergeable if other lemmata have a different lemma" do
    l1 = FactoryGirl.create(:lemma, variant: 1, lemma: 'sum')
    l2 = FactoryGirl.create(:lemma, variant: 2, lemma: 'fio')

    l1.mergeable?(l2).should be_false
    l2.mergeable?(l1).should be_false
  end

  it "is not mergeable if other lemmata have a different language tag" do
    l1 = FactoryGirl.create(:lemma, variant: 1, language_tag: 'got')
    l2 = FactoryGirl.create(:lemma, variant: 2, language_tag: 'lat')

    l1.mergeable?(l2).should be_false
    l2.mergeable?(l1).should be_false
  end

  it "is not mergeable if other lemmata have a different part of speech tag" do
    l1 = FactoryGirl.create(:lemma, variant: 1, part_of_speech_tag: 'V-')
    l2 = FactoryGirl.create(:lemma, variant: 2, part_of_speech_tag: 'R-')

    l1.mergeable?(l2).should be_false
    l2.mergeable?(l1).should be_false
  end

  it "returns all mergeable lemmata" do
    l1 = FactoryGirl.create(:lemma, variant: 1)
    l2 = FactoryGirl.create(:lemma, variant: 2)
    l3 = FactoryGirl.create(:lemma, variant: nil)
    l4 = FactoryGirl.create(:lemma, lemma: 'fio')

    l1.mergeable_lemmata.map(&:export_form).sort.should eq %w(sum sum#2)
    l2.mergeable_lemmata.map(&:export_form).sort.should eq %w(sum sum#1)
    l3.mergeable_lemmata.map(&:export_form).sort.should eq %w(sum#1 sum#2)
    l4.mergeable_lemmata.map(&:export_form).sort.should eq %w()
  end

  it "can be merged with a mergeable lemma" do
    l1 = FactoryGirl.create(:lemma, variant: 1)
    l2 = FactoryGirl.create(:lemma, variant: 2)

    l1.merge! l2
  end

  it "cannot be merged with an unmergeable lemma" do
    l1 = FactoryGirl.create(:lemma, lemma: 'sum')
    l2 = FactoryGirl.create(:lemma, lemma: 'fio')

    lambda { l1.merge! l2 }.should raise_error(ArgumentError)
  end
end
