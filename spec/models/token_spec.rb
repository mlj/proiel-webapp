require 'rails_helper'

RSpec.describe Token, type: :model do
  fixtures :sentences
  fixtures :tokens

  it "tests relation predicates" do
    s = Sentence.first

    t = s.tokens.new(form: 'foo')
    t.relation = :xobj
    expect(t.predicative?).to be_truthy
    expect(t.appositive?).to be_falsey
    expect(t.nominal?).to be_falsey

    t = s.tokens.new(form: 'foo')
    t.relation = :voc
    expect(t.predicative?).to be_falsey
    expect(t.appositive?).to be_falsey
    expect(t.nominal?).to be_truthy

    t = s.tokens.new(form: 'foo')
    t.relation = :apos
    expect(t.predicative?).to be_falsey
    expect(t.appositive?).to be_truthy
    expect(t.nominal?).to be_falsey
  end

  it "tests morphology feature predicates" do
    s = Sentence.first # associate our tokens with a random sentence

    t = s.tokens.new(form: 'foo')
    t.morph_features = MorphFeatures.new('foo,V-,lat', '---------n')
    expect(t.verb?).to be_truthy
    expect(t.verb?(true)).to be_truthy
    expect(t.verb?(false)).to be_truthy
    expect(t.conjunction?).to be_falsey
    expect(t.conjunction?(true)).to be_falsey
    expect(t.conjunction?(false)).to be_falsey
    expect(t.noun?).to be_falsey
    expect(t.article?).to be_falsey
    expect(t.pronoun?).to be_falsey

    t.morph_features = MorphFeatures.new('foo,C-,lat', '---------n')
    expect(t.conjunction?).to be_truthy
    expect(t.conjunction?(true)).to be_truthy
    expect(t.conjunction?(false)).to be_truthy

    t.morph_features = MorphFeatures.new('foo,Nb,lat', '---------n')
    expect(t.noun?).to be_truthy

    t.morph_features = MorphFeatures.new('foo,S-,grc', '---------n')
    expect(t.article?).to be_truthy

    t.morph_features = MorphFeatures.new('foo,Pr,lat', '---------n')
    expect(t.pronoun?).to be_truthy

    # Test empty tokens
    t.form = nil
    t.empty_token_sort = 'C'
    t.morph_features = nil
    expect(t.conjunction?).to be_truthy
    expect(t.conjunction?(true)).to be_truthy
    expect(t.conjunction?(false)).to be_falsey
    expect(t.verb?).to be_falsey
    expect(t.verb?(true)).to be_falsey
    expect(t.verb?(false)).to be_falsey

    t.form = nil
    t.empty_token_sort = 'V'
    t.morph_features = nil
    expect(t.conjunction?).to be_falsey
    expect(t.conjunction?(true)).to be_falsey
    expect(t.conjunction?(false)).to be_falsey
    expect(t.verb?).to be_truthy
    expect(t.verb?(true)).to be_truthy
    expect(t.verb?(false)).to be_falsey
  end

  it "returns RelationTag objects" do
    t = tokens(:one)
    t.relation = 'pred'
    t.save!
    expect(RelationTag.new('pred')).to eq t.relation

    t = tokens(:one)
    t.relation = 'obl'
    t.save!
    expect(RelationTag.new('obl')).to eq t.relation

    t = tokens(:one)
    t.relation = :pred
    t.save!
    expect(RelationTag.new('pred')).to eq t.relation

    t = tokens(:one)
    t.relation = 'obl'
    t.save!
    expect(RelationTag.new('obl')).to eq t.relation
  end

  context "splitable and non-splitable tokens" do
    it "detects that a single word is not splitable" do
      t = tokens(:latin_word)
      expect(t.is_splitable?).to be_truthy
    end

    it "detects that a single-letter Latin token is not splitable" do
      t = tokens(:latin_single_letter_word)
      expect(t.is_splitable?).to be_falsy
    end

    it "detects that a single-letter non-Latin token is not splitable" do
      t = tokens(:greek_single_letter_word)
      expect(t.is_splitable?).to be_falsy
    end

    it "detects that an empty token is not splitable" do
      t = tokens(:empty)
      expect(t.is_splitable?).to be_falsy
    end
  end
end
