require 'test_helper'

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
end
