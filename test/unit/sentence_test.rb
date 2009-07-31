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


  def test_presentation_as_editable_html
    s = Sentence.first
    s.presentation = "<w>sic</w> <w>vocibus</w> <w>consulis</w><pc>,</pc> <w>terrore</w> <w>praesentis</w> <w>exercitus</w><pc>,</pc> <w>minis</w> <w>amicorum</w> <w>Pompei</w> <w>pleri</w><w>que</w> <w>compulsi</w> <w>inviti</w> <w>et</w> <w>coacti</w> <w>Scipionis</w> <w>sententiam</w> <w>sequuntur</w>"
    assert_equal('<span class="w">sic</span> <span class="w">vocibus</span> <span class="w">consulis</span><span class="pc">,</span> <span class="w">terrore</span> <span class="w">praesentis</span> <span class="w">exercitus</span><span class="pc">,</span> <span class="w">minis</span> <span class="w">amicorum</span> <span class="w">Pompei</span> <span class="w">pleri</span><span class="w">que</span> <span class="w">compulsi</span> <span class="w">inviti</span> <span class="w">et</span> <span class="w">coacti</span> <span class="w">Scipionis</span> <span class="w">sententiam</span> <span class="w">sequuntur</span>', s.presentation_as_editable_html)
  end
end
