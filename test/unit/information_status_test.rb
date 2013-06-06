require File.dirname(__FILE__) + '/../test_helper'

class InformationStatusTestCase < ActiveSupport::TestCase
  def setup
    @anaphor1 = tokens(:information_structure_anaphor1)
    @anaphor2 = tokens(:information_structure_anaphor2)
    @anaphor3 = tokens(:information_structure_anaphor3)
    @antecedent = tokens(:information_structure_antecedent)
  end

  def test_antecedent_association
    assert_equal @antecedent.id, @anaphor1.antecedent_id
    assert_equal @antecedent.id, @anaphor2.antecedent_id
    assert_equal @antecedent.id, @anaphor3.antecedent_id

    assert_equal @antecedent, @anaphor1.antecedent
    assert_equal @antecedent, @anaphor2.antecedent
    assert_equal @antecedent, @anaphor3.antecedent
  end

  def test_ananphors_relation
    assert_equal [@anaphor1, @anaphor2, @anaphor3].sort, @antecedent.anaphors.sort
  end

  def test_nearest_anaphor
    assert_equal @anaphor1, @antecedent.nearest_anaphor
  end

  def test_word_distance_between
    assert_equal 0, @antecedent.word_distance_between(@antecedent)

    assert_equal 2, @antecedent.word_distance_between(@anaphor1)
    assert_equal 4, @antecedent.word_distance_between(@anaphor2)
    assert_equal 6, @antecedent.word_distance_between(@anaphor3)

    assert_equal 2, @anaphor1.word_distance_between(@antecedent)
    assert_equal 4, @anaphor2.word_distance_between(@antecedent)
    assert_equal 6, @anaphor3.word_distance_between(@antecedent)
  end

  def test_sentence_distance_between
    assert_equal 0, @antecedent.sentence_distance_between(@antecedent)

    assert_equal 0, @antecedent.sentence_distance_between(@anaphor1)
    assert_equal 0, @antecedent.sentence_distance_between(@anaphor2)
    assert_equal 1, @antecedent.sentence_distance_between(@anaphor3)

    assert_equal 0, @anaphor1.sentence_distance_between(@antecedent)
    assert_equal 0, @anaphor2.sentence_distance_between(@antecedent)
    assert_equal 1, @anaphor3.sentence_distance_between(@antecedent)
  end
end
