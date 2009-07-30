require File.dirname(__FILE__) + '/../test_helper'

class SentenceTest < ActiveSupport::TestCase
  def setup
    @sentence = Sentence.find(1)
  end

  def test_model
    assert_kind_of Sentence, @sentence
  end

  def test_presentation_as_reference
    s = Sentence.first
    s.presentation = "<milestone n=\"1\" unit=\"act\" /><milestone n=\"prol\" unit=\"scene\" /> <speaker>Mercvrivs</speaker> <milestone n=\"1\" unit=\"line\" ed=\"TLN\" /><lb />Vt vos in vostris voltis mercimoniis <milestone n=\"2\" unit=\"line\" ed=\"TLN\" /><lb />emundis vendundisque me laetum lucris <milestone n=\"3\" unit=\"line\" ed=\"TLN\" /><lb />adficere atque adiuvare in rebus omnibus"
    assert_equal "act=1,scene=prol,line=1,line=2,line=3,", s.send(:presentation_as, APPLICATION_CONFIG.presentation_as_reference_stylesheet)
    assert_equal({"line"=>["1", "2", "3"], "scene"=>"prol", "act"=>"1"}, s.presentation_as_reference)
  end
end
