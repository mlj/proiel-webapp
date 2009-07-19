require File.dirname(__FILE__) + '/../test_helper'

class TokenTest < ActiveSupport::TestCase
  fixtures :tokens

  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_relation_predicates
    s = Sentence.first

    t = Token.new(:sentence => s, :form => 'foo')
    t.relation = :xobj
    assert t.predicative?
    assert !t.appositive?
    assert !t.nominal?

    t = Token.new(:sentence => s, :form => 'foo')
    t.relation = :voc
    assert !t.predicative?
    assert !t.appositive?
    assert t.nominal?

    t = Token.new(:sentence => s, :form => 'foo')
    t.relation = :apos
    assert !t.predicative?
    assert t.appositive?
    assert !t.nominal?
  end

  def test_morph_feature_predicates
    s = Sentence.first # associate our tokens with a random sentence

    t = Token.new(:sentence => s, :form => 'foo')
    t.morph_features = MorphFeatures.new('foo,V-,lat', '----------n')
    assert t.verb?
    assert t.verb?(true)
    assert t.verb?(false)
    assert !t.conjunction?
    assert !t.conjunction?(true)
    assert !t.conjunction?(false)
    assert !t.noun?
    assert !t.article?
    assert !t.pronoun?

    t.morph_features = MorphFeatures.new('foo,C-,lat', '----------n')
    assert t.conjunction?
    assert t.conjunction?(true)
    assert t.conjunction?(false)

    t.morph_features = MorphFeatures.new('foo,Nb,lat', '----------n')
    assert t.noun?

    t.morph_features = MorphFeatures.new('foo,S-,grc', '----------n')
    assert t.article?

    t.morph_features = MorphFeatures.new('foo,Pr,lat', '----------n')
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
end
