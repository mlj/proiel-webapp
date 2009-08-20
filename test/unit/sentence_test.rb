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

    # Handle del within w
    s.presentation = "<w>anstai</w><s> </s><w>sijuþ</w><s> </s><w>ganasidai</w><pc>—</pc><s> </s><s> </s><milestone n='6' unit='verse'/><s> </s><w>jah</w><s> </s><w>miþurraisida</w><s> </s><w>jah</w><s> </s><w>miþgasatida</w><s> </s><w>in</w><s> </s><w>himinakundaim</w><s> </s><w>in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>,</pc><s> </s><s> </s><milestone n='7' unit='verse'/><s> </s><w>ei</w><s> </s><w>ataugjai</w><s> </s><w>in</w><s> </s><w>ald<del>a</del>im</w><s> </s><w>þaim</w><s> </s><w>anagaggandeim</w><s> </s><w>ufarassu</w><s> </s><w>gabeins</w><s> </s><w>anstais</w><s> </s><w>seinaizos</w><s> </s><w>in</w><s> </s><w>selein</w><s> </s><w>bi</w><s> </s><w>uns</w><s> </s><w>in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>.</pc>"
    assert_equal ["anstai", "sijuþ", "ganasidai", "jah", "miþurraisida", "jah", "miþgasatida", "in", "himinakundaim", "in", "Xristau", "Iesu", "ei", "ataugjai", "in", "aldim", "þaim", "anagaggandeim", "ufarassu", "gabeins", "anstais", "seinaizos", "in", "selein", "bi", "uns", "in", "Xristau", "Iesu"], s.presentation_as_tokens
  end

  def test_presentation_well_formed?
    s = Sentence.new

    s.presentation = "<w>anstai</w><s> </s><w>sijuþ</w><s> </s><w>ganasidai</w><pc>—</pc><s> </s><s> </s><milestone n='6' unit='verse'/><s> </s><w>jah</w><s> </s><w>miþurraisida</w><s> </s><w>jah</w><s> </s><w>miþgasatida</w><s> </s><w>in</w><s> </s><w>himinakundaim</w><s> </s><w>in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>,</pc><s> </s><s> </s><milestone n='7' unit='verse'/><s> </s><w>ei</w><s> </s><w>ataugjai</w><s> </s><w>in</w><s> </s><w>ald<del>a</del>im</w><s> </s><w>þaim</w><s> </s><w>anagaggandeim</w><s> </s><w>ufarassu</w><s> </s><w>gabeins</w><s> </s><w>anstais</w><s> </s><w>seinaizos</w><s> </s><w>in</w><s> </s><w>selein</w><s> </s><w>bi</w><s> </s><w>uns</w><s> </s><w>in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>.</pc>"
    assert s.presentation_well_formed?
    assert s.valid?

    # Missing closing tag.
    s.presentation = "<w>in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>."
    assert !s.presentation_well_formed?
    assert !s.valid?

    # Missing opening tag.
    s.presentation = "in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>.</pc>"
    assert !s.presentation_well_formed?
    assert !s.valid?

    # Unescaped ampersand
    s.presentation = "&<w>in</w><s> </s><w>Xristau</w><s> </s><w>Iesu</w><pc>.</pc>"
    assert !s.presentation_well_formed?
    assert !s.valid?
  end
end
