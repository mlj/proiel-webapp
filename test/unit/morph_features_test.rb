require 'test_helper'

class MorphFeaturesTestCase < ActiveSupport::TestCase
  def setup
    @dq = MorphFeatures.new(',Dq,lat', '----------')
    @cum_dq = MorphFeatures.new('cum,Dq,lat', '-----------')
    @cum1_dq = MorphFeatures.new('cum#1,Dq,lat', '----------')
    @sine1_dq = MorphFeatures.new('sine#1,Dq,lat', '----------')
    @cur1_a  = MorphFeatures.new('cur#1,A,lat', '----------')
    @cur_dq = MorphFeatures.new('cur,Dq,lat', '----------')
    @cur1_dq = MorphFeatures.new('cur#1,Dq,lat', '----------')
    @cur1_dq_n = MorphFeatures.new('cur#1,Dq,lat', '---------n')
    @cur2_dq = MorphFeatures.new('cur#2,Dq,lat', '----------')
    @cur1_pr = MorphFeatures.new('cur#1,Pr,lat', '----------')
    @dq_n = MorphFeatures.new(',Dq,lat', '---------n')
    @dq_i = MorphFeatures.new(',Dq,lat', '---------i')
    @some_verb = MorphFeatures.new('foo,V-,lat', '3s-ip----i')
  end

  def test_separate_initialisation
    m = MorphFeatures.new('cur,Dq,lat', '---------n')
    assert_equal 'cur,Dq,lat', m.lemma_s
    assert_equal 'Dq', m.pos_s
    assert_equal 'lat', m.language_s
    assert_equal '---------n', m.morphology_s

    assert_equal 'cur', m.lemma.lemma
    assert_equal 'Dq', m.lemma.part_of_speech.tag
    assert_nil m.lemma.variant

    assert_equal "cur,Dq,lat,---------n", m.to_s
  end

  def test_separate_initialisation_with_variant_number
    m = MorphFeatures.new('cur#2,Dq,lat', nil)
    assert_equal 'cur#2,Dq,lat', m.lemma_s
    assert_equal 'Dq', m.pos_s
    assert_equal 'lat', m.language_s
    assert_equal '----------', m.morphology_s

    assert_equal 'cur', m.lemma.lemma
    assert_equal 'Dq', m.lemma.part_of_speech.tag
    assert_equal 2, m.lemma.variant

    assert_equal "cur#2,Dq,lat,----------", m.to_s
  end

  def test_separate_initialisation_with_abbreviated_morphology
    m = MorphFeatures.new('cur,Dq,lat', 'h')
    assert_equal 'cur,Dq,lat', m.lemma_s
    assert_equal 'Dq', m.pos_s
    assert_equal 'lat', m.language_s
    assert_equal 'h---------', m.morphology_s

    assert_equal 'cur', m.lemma.lemma
    assert_equal 'Dq', m.lemma.part_of_speech.tag
    assert_nil m.lemma.variant

    assert_equal "cur,Dq,lat,h---------", m.to_s
  end

  def test_separate_initialisation_without_morphology
    m = MorphFeatures.new('cur,Dq,lat', nil)
    assert_equal 'cur,Dq,lat', m.lemma_s
    assert_equal 'Dq', m.pos_s
    assert_equal 'lat', m.language_s
    assert_equal '----------', m.morphology_s

    assert_equal 'cur', m.lemma.lemma
    assert_equal 'Dq', m.lemma.part_of_speech.tag
    assert_nil m.lemma.variant

    assert_equal "cur,Dq,lat,----------", m.to_s
  end

  def test_separate_initialisation_without_lemma_but_pos
    m = MorphFeatures.new(',Dq,lat', '---------n')
    assert_equal ',Dq,lat', m.lemma_s
    assert_equal 'Dq', m.pos_s
    assert_equal 'lat', m.language_s
    assert_equal '---------n', m.morphology_s

    assert_nil m.lemma.lemma
    assert_equal 'Dq', m.lemma.part_of_speech.tag
    assert_nil m.lemma.variant

    assert_equal ",Dq,lat,---------n", m.to_s
  end

  def test_uninitialized_morphology
    m = MorphFeatures.new(',Df,lat', '----------')
    assert_equal 'Df', m.pos_s
    assert_equal '----------', m.morphology_s
  end

  def test_comparison
    assert_equal 0, @cur2_dq <=> @cur2_dq

    assert_equal -1, @cur1_dq <=> @cur2_dq
    assert_equal 1, @cur2_dq <=> @cur1_dq

    assert_equal -1, @cur1_a <=> @cur1_dq
    assert_equal 1, @cur1_pr <=> @cur1_dq

    assert_equal -1, @cum1_dq <=> @cur1_dq
    assert_equal 1, @sine1_dq <=> @cur1_dq

    assert_equal -1, @cum_dq <=> @cum1_dq
    assert_equal 1, @cum1_dq <=> @cum_dq

    assert_equal -1, @dq <=> @cum_dq
    assert_equal 1, @cum_dq <=> @dq

    assert_equal -1, @dq <=> @cum1_dq
    assert_equal 1, @cum1_dq <=> @dq
  end

  def test_pos_s
    assert_equal 'Df', MorphFeatures.new(',Df,lat', nil).pos_s
    assert_equal 'R-', MorphFeatures.new(',R-,lat', nil).pos_s
  end

  def test_morphology_s
    assert_equal '-------p--', MorphFeatures.new(',Df,lat','-------p').morphology_s
    assert_equal '-------p--', MorphFeatures.new(',Df,lat','-------p-').morphology_s
    assert_equal '-------p--', MorphFeatures.new(',Df,lat','-------p--').morphology_s
  end

  def test_validity
    assert_equal false, MorphFeatures.new('foo,A-,lat', '-s---na--i').valid?
    assert_equal false, MorphFeatures.new('foo,A-,grc', '-s---na--i').valid?
    assert_equal true,  MorphFeatures.new('foo,A-,lat', '-p---mdp-i').valid?
    assert_equal false, MorphFeatures.new('foo,V-,lat', '3piie----i').valid?
    assert_equal true,  MorphFeatures.new('foo,V-,grc', '3piie----i').valid?
    assert_equal true,  MorphFeatures.new('foo,Pd,lat', '-p---nd--i').valid?
    assert_equal true,  MorphFeatures.new('foo,Pi,lat', '-p---mn--i').valid?
    assert_equal true,  MorphFeatures.new('foo,Pk,lat', '3p---mb--i').valid? # personal reflexive
    assert_equal true,  MorphFeatures.new('foo,V-,lat', '-pppama--i').valid? # present participle
    assert_equal true,  MorphFeatures.new('foo,V-,lat', '2sfip----i').valid? # future indicative
    assert_equal true,  MorphFeatures.new('foo,V-,lat', '---u--d--i').valid? # supine, dative
  end

  def test_completions
    assert_equal [
      "foo,Nb,lat,-s---mn--i",
      "foo,Ne,lat,-s---mn--i"
    ], MorphFeatures.new('foo,N-,lat', '-s---mn---').completions.map(&:to_s).sort

    assert_equal [
      "foo,Nb,lat,-p---mn--i",
      "foo,Nb,lat,-s---mn--i"
    ], MorphFeatures.new('foo,Nb,lat', '-----mn--i').completions.map(&:to_s).sort

    assert_equal [
      "foo,Nb,chu,-d---ma--i",
      "foo,Nb,chu,-p---ma--i",
      "foo,Nb,chu,-s---ma--i",
    ], MorphFeatures.new('foo,Nb,chu', '-----ma--i').completions.map(&:to_s).sort

    assert_equal [
      "foo,Nb,chu,-d---mn--i",
      "foo,Nb,chu,-p---mn--i",
      "foo,Nb,chu,-s---mn--i"
    ], MorphFeatures.new('foo,Nb,chu', '-----mn--i').completions.map(&:to_s).sort
  end
end
