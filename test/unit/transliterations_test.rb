# encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'
require 'transliterations'

class TransliterationTestCase < ActiveSupport::TestCase
  def xlit_sentence(t, e, s)
    e.split(/\s+/).zip(s.split(/\s+/)).each do |x, y|
      assert_equal [Unicode.normalize_C(x)], t.transliterate_string(y)
    end
  end

  def test_grc_betacode
    x = TransliteratorFactory::get_transliterator("grc-betacode")
    assert_equal [Unicode.normalize_C("ἐν")], x.transliterate_string("E)N")
    assert_equal [Unicode.normalize_C("ὁ")], x.transliterate_string("O(")
    assert_equal [Unicode.normalize_C("οἱ")], x.transliterate_string("OI(")
    assert_equal [Unicode.normalize_C("πρός"),], x.transliterate_string("PRO/S")
    assert_equal [Unicode.normalize_C("τῶν")], x.transliterate_string("TW=N")
    assert_equal [Unicode.normalize_C("πρὸς")], x.transliterate_string("PRO\\S")
    assert_equal [Unicode.normalize_C("προϊέναι")], x.transliterate_string("PROI+E/NAI")
    assert_equal [Unicode.normalize_C("τῷ")], x.transliterate_string("TW=|")
    assert_equal [Unicode.normalize_C("μαχαίρᾱς")], x.transliterate_string("MAXAI/RA%26S")
    assert_equal [Unicode.normalize_C("μάχαιρᾰ")], x.transliterate_string("MA/XAIRA%27")

    assert_equal [Unicode.normalize_C("ΕΣΤΙΝ")], x.transliterate_string("*e*s*t*i*n")
    assert_equal [Unicode.normalize_C("Ἐστιν")], x.transliterate_string("*e)stin")
    assert_equal [Unicode.normalize_C("ἐστιν")], x.transliterate_string("e)stin")
    assert_equal [Unicode.normalize_C("Ὡς")], x.transliterate_string("*w(j")
    assert_equal [Unicode.normalize_C("ὡς")], x.transliterate_string("w(j")
    assert_equal [Unicode.normalize_C("ὁ")], x.transliterate_string("o(")
    assert_equal [Unicode.normalize_C("Ἡ")], x.transliterate_string("*h(")
    xlit_sentence(x, "Ὅτε ὁ φίλος ἀπέθανεν", "*o(/te o( fi/loj a)pe/qanen")
    xlit_sentence(x, "ὁ ἐμὸς καὶ σὸς φίλος", "o( e)mo\\j kai\\ so\\j fi/loj")
    xlit_sentence(x, "Ἆρ' ὁ δοῦλος ἧκεν", "*a)=r' o( dou=loj h(=ken")
    assert_equal [Unicode.normalize_C("θυΐδιον")], x.transliterate_string("qui+/dion")
    assert_equal [Unicode.normalize_C("θῠϊνος")], x.transliterate_string("qu%27i+noj")
    assert_equal [Unicode.normalize_C("γεφῡρίζω")], x.transliterate_string("gefu%26ri/zw")
    assert_equal [Unicode.normalize_C("γέφῡρᾰ")], x.transliterate_string("ge/fu%26ra%27")
  end
end
    
