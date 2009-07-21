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
    s.presentation = "<w>sic</w><s> </s><w>vocibus</w><s> </s><w>consulis</w><pc>,</pc><s> </s><w>terrore</w><s> </s><w>praesentis</w><s> </s><w>exercitus</w><pc>,</pc><s> </s><w>minis</w><s> </s><w>amicorum</w><s> </s><w>Pompei</w><s> </s><w>pleri</w><w>que</w><s> </s><w>compulsi</w><s> </s><w>inviti</w><s> </s><w>et</w><s> </s><w>coacti</w><s> </s><w>Scipionis</w><s> </s><w>sententiam</w><s> </s><w>sequuntur</w>"
    assert_equal("<span class=\"w\">sic</span><span class=\"s\"> </span><span class=\"w\">vocibus</span><span class=\"s\"> </span><span class=\"w\">consulis</span><span class=\"pc\">,</span><span class=\"s\"> </span><span class=\"w\">terrore</span><span class=\"s\"> </span><span class=\"w\">praesentis</span><span class=\"s\"> </span><span class=\"w\">exercitus</span><span class=\"pc\">,</span><span class=\"s\"> </span><span class=\"w\">minis</span><span class=\"s\"> </span><span class=\"w\">amicorum</span><span class=\"s\"> </span><span class=\"w\">Pompei</span><span class=\"s\"> </span><span class=\"w\">pleri</span><span class=\"w\">que</span><span class=\"s\"> </span><span class=\"w\">compulsi</span><span class=\"s\"> </span><span class=\"w\">inviti</span><span class=\"s\"> </span><span class=\"w\">et</span><span class=\"s\"> </span><span class=\"w\">coacti</span><span class=\"s\"> </span><span class=\"w\">Scipionis</span><span class=\"s\"> </span><span class=\"w\">sententiam</span><span class=\"s\"> </span><span class=\"w\">sequuntur</span>", s.presentation_as_editable_html)
  end

  def test_presentation_as_tokens
    s = Sentence.new

    s.presentation = '<milestone n="4" unit="act" /><milestone n="2" unit="scene" /> <speaker>Mercvrivs</speaker> <milestone n="1021" unit="line" ed="TLN" /><lb /><w>Quís</w> <w>ad</w> <w>fores</w> <w>est</w>?'
    assert_equal ["Quís", "ad", "fores", "est"], s.presentation_as_tokens

    s.presentation = '<speaker>(Merc.)</speaker> <milestone n="1034f" unit="line" ed="TLN" /><lb /><expan abbr="Laruatu\'s"><w>laruatus</w> <w>es</w></expan>.'
    assert_equal ["laruatus", "es"], s.presentation_as_tokens

    s.presentation = '<w>hoc</w> <w>unum</w> <del>inopia navium</del> <w>Caesari</w> <w>ad</w> <w>celeritatem</w> <w>conficiendi</w> <w>belli</w> <w>defuit</w>.'
    assert_equal ["hoc", "unum", "Caesari", "ad", "celeritatem", "conficiendi", "belli", "defuit"], s.presentation_as_tokens

    s.presentation = '<gap />;<w>neque</w> <w>enim</w> <w>ex</w> <w>Marsis</w> <w>Paelignis</w><w>que</w> <w>veniebant</w> <w>ut</w> <w>qui</w> <w>superiore</w> <w>nocte</w> <w>in</w> <w>contuberniis</w> <w>commilitones</w><w>que</w> <gap />.'
    assert_equal ["neque", "enim", "ex", "Marsis", "Paelignis", "que", "veniebant", "ut", "qui", "superiore", "nocte", "in", "contuberniis", "commilitones", "que"], s.presentation_as_tokens

    s.presentation = 'neque enim ex Marsis'
    assert_equal [], s.presentation_as_tokens
  end
end
