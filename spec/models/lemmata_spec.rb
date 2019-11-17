RSpec.describe Lemma, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.create(:lemma)).to be_valid
  end

  it "is invalid without a language tag" do
    expect(FactoryGirl.build(:lemma, language_tag: nil)).not_to be_valid
  end

  it "is invalid if language tag is bogus" do
    expect(FactoryGirl.build(:lemma, language_tag: 'XXX')).not_to be_valid
  end

  it "is invalid without a part of speech tag" do
    expect(FactoryGirl.build(:lemma, part_of_speech_tag: nil)).not_to be_valid
  end

  it "is invalid if part of speech tag is bogus" do
    expect(FactoryGirl.build(:lemma, part_of_speech_tag: 'XX')).not_to be_valid
  end

  it "is invalid without a lemma" do
    expect(FactoryGirl.build(:lemma, lemma: nil)).not_to be_valid
  end

  it "is valid if the variant number is an integer" do
    expect(FactoryGirl.build(:lemma, variant: 0)).to be_valid
    expect(FactoryGirl.build(:lemma, variant: 1)).to be_valid
    expect(FactoryGirl.build(:lemma, variant: -1)).to be_valid
    expect(FactoryGirl.build(:lemma, variant: 12345)).to be_valid
    expect(FactoryGirl.build(:lemma, variant: '1')).to be_valid
    expect(FactoryGirl.build(:lemma, variant: '0')).to be_valid
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
    expect(lemma.language_tag).to eq 'lat'
    expect(lemma.language).to eq LanguageTag.new('lat')
    # FIXME: ideally these objects should also be identical
    #lemma.language.should be LanguageTag.new('lat')
  end

  it "returns a part of speech tag and a part of speech object" do
    lemma = FactoryGirl.create(:lemma)
    expect(lemma.part_of_speech_tag).to eq 'V-'
    expect(lemma.part_of_speech).to eq PartOfSpeechTag.new('V-')
    # FIXME: ideally these objects should also be identical
    #lemma.part_of_speech.should be PartOfSpeechTag.new('V-')
  end

  it "returns a part of speech tag and a part of speech object" do
    lemma = FactoryGirl.create(:lemma)
    expect(lemma.lemma).to eq 'sum'
  end

  it "returns all represented languages" do
    languages = %w(lat grc chu)

    languages.each do |l|
      FactoryGirl.create(:lemma, language_tag: l)
    end

    language_tags = languages.map { |l| LanguageTag.new(l) }

    expect(Lemma.represented_languages.sort_by(&:tag)).to eq language_tags.sort_by(&:tag)
  end

  it "returns all represented languages in correct order" do
    languages = %w(lat grc chu)

    languages.each do |l|
      FactoryGirl.create(:lemma, language_tag: l)
    end

    language_tags = languages.map { |l| LanguageTag.new(l) }

    expect(Lemma.represented_languages).to eq language_tags.sort_by(&:to_label)
  end

  it "is mergeable if other lemmata have the same lemma, language tag and part of speech tag" do
    l1 = FactoryGirl.create(:lemma, variant: 1)
    l2 = FactoryGirl.create(:lemma, variant: 2)

    expect(l1.mergeable?(l2)).to be_truthy
    expect(l2.mergeable?(l1)).to be_truthy
  end

  it "is not mergeable if other lemmata have a different lemma" do
    l1 = FactoryGirl.create(:lemma, variant: 1, lemma: 'sum')
    l2 = FactoryGirl.create(:lemma, variant: 2, lemma: 'fio')

    expect(l1.mergeable?(l2)).to be_falsey
    expect(l2.mergeable?(l1)).to be_falsey
  end

  it "is not mergeable if other lemmata have a different language tag" do
    l1 = FactoryGirl.create(:lemma, variant: 1, language_tag: 'got')
    l2 = FactoryGirl.create(:lemma, variant: 2, language_tag: 'lat')

    expect(l1.mergeable?(l2)).to be_falsey
    expect(l2.mergeable?(l1)).to be_falsey
  end

  it "is not mergeable if other lemmata have a different part of speech tag" do
    l1 = FactoryGirl.create(:lemma, variant: 1, part_of_speech_tag: 'V-')
    l2 = FactoryGirl.create(:lemma, variant: 2, part_of_speech_tag: 'R-')

    expect(l1.mergeable?(l2)).to be_falsey
    expect(l2.mergeable?(l1)).to be_falsey
  end

  it "returns all mergeable lemmata" do
    l1 = FactoryGirl.create(:lemma, variant: 1)
    l2 = FactoryGirl.create(:lemma, variant: 2)
    l3 = FactoryGirl.create(:lemma, variant: nil)
    l4 = FactoryGirl.create(:lemma, lemma: 'fio')

    expect(l1.mergeable_lemmata.map(&:export_form).sort).to eq %w(sum sum#2)
    expect(l2.mergeable_lemmata.map(&:export_form).sort).to eq %w(sum sum#1)
    expect(l3.mergeable_lemmata.map(&:export_form).sort).to eq %w(sum#1 sum#2)
    expect(l4.mergeable_lemmata.map(&:export_form).sort).to eq %w()
  end

  it "can be merged with a mergeable lemma" do
    l1 = FactoryGirl.create(:lemma, variant: 1)
    l2 = FactoryGirl.create(:lemma, variant: 2)

    l1.merge! l2
  end

  it "cannot be merged with an unmergeable lemma" do
    l1 = FactoryGirl.create(:lemma, lemma: 'sum')
    l2 = FactoryGirl.create(:lemma, lemma: 'fio')

    expect { l1.merge! l2 }.to raise_error(ArgumentError)
  end
end
