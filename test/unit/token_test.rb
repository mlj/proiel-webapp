require File.dirname(__FILE__) + '/../test_helper'

class TokenTest < ActiveSupport::TestCase
  fixtures :tokens

  def test_relation_predicates
    s = Sentence.first

    t = s.tokens.new(:form => 'foo')
    t.relation = :xobj
    assert t.predicative?
    assert !t.appositive?
    assert !t.nominal?

    t = s.tokens.new(:form => 'foo')
    t.relation = :voc
    assert !t.predicative?
    assert !t.appositive?
    assert t.nominal?

    t = s.tokens.new(:form => 'foo')
    t.relation = :apos
    assert !t.predicative?
    assert t.appositive?
    assert !t.nominal?
  end

  def test_morph_feature_predicates
    s = Sentence.first # associate our tokens with a random sentence

    t = s.tokens.new(:form => 'foo')
    t.morph_features = MorphFeatures.new('foo,V-,lat', '---------n')
    assert t.verb?
    assert t.verb?(true)
    assert t.verb?(false)
    assert !t.conjunction?
    assert !t.conjunction?(true)
    assert !t.conjunction?(false)
    assert !t.noun?
    assert !t.article?
    assert !t.pronoun?

    t.morph_features = MorphFeatures.new('foo,C-,lat', '---------n')
    assert t.conjunction?
    assert t.conjunction?(true)
    assert t.conjunction?(false)

    t.morph_features = MorphFeatures.new('foo,Nb,lat', '---------n')
    assert t.noun?

    t.morph_features = MorphFeatures.new('foo,S-,grc', '---------n')
    assert t.article?

    t.morph_features = MorphFeatures.new('foo,Pr,lat', '---------n')
    assert t.pronoun?

    # Test empty tokens
    t.form = nil
    t.empty_token_sort = 'C'
    t.morph_features = nil
    assert t.conjunction?
    assert t.conjunction?(true)
    assert !t.conjunction?(false)
    assert !t.verb?
    assert !t.verb?(true)
    assert !t.verb?(false)

    t.form = nil
    t.empty_token_sort = 'V'
    t.morph_features = nil
    assert !t.conjunction?
    assert !t.conjunction?(true)
    assert !t.conjunction?(false)
    assert t.verb?
    assert t.verb?(true)
    assert !t.verb?(false)
  end

  def test_relation_assignment
    t = Token.first
    t.relation = 'pred'
    t.save!
    assert_equal RelationTag.new('pred'), t.relation

    t = Token.first
    t.relation = 'obl'
    t.save!
    assert_equal RelationTag.new('obl'), t.relation

    t = Token.first
    t.relation = :pred
    t.save!
    assert_equal RelationTag.new('pred'), t.relation

    t = Token.first
    t.relation = 'obl'
    t.save!
    assert_equal RelationTag.new('obl'), t.relation
  end

  # Splitting and merging of tokens
  def test_is_splitable
    t = tokens(:latin_word)
    assert t.is_splitable?

    t = tokens(:empty)
    assert !t.is_splitable?

    t = tokens(:latin_single_letter_word)
    assert !t.is_splitable?

    t = tokens(:greek_single_letter_word)
    assert !t.is_splitable?
  end
end
