require 'trie'
require 'xmlsimple'

DATADIR = File.expand_path(File.dirname(__FILE__))

class Transliterator
  def initialize(data_file)
    @t = Trie.new
    XmlSimple.xml_in(File.join(DATADIR, data_file))['entry'].each do |v|
      @t.insert(v['key'][0].split(''), v['value'][0])
    end
  end

  def convert(s)
    t = @t
    r = s.split('').inject('') { |r, c|
      new_t = t.find_prefix(c)
      if new_t.empty?
        #FIXME assert that t.values.length == 1
        r << t.values[0]
        t = @t.find_prefix(c)
      else
        t = new_t
      end
      r
    }
    r << t.values[0]
  end
end

BETA_CODE = Transliterator.new('betacode.xml').freeze

if $0 == __FILE__
  require 'test/unit'

  class BetaCodeTestCase < Test::Unit::TestCase
    def test_beta_code_convert
      assert_equal "ἐν", BETA_CODE.convert('E)N')
      assert_equal "οἱ", BETA_CODE.convert('OI(')
      assert_equal "πρός", BETA_CODE.convert('PRO/S')
      assert_equal "τῶν", BETA_CODE.convert('TW=N')
      assert_equal "πρὸς", BETA_CODE.convert('PRO\S')
      assert_equal "προϊέναι", BETA_CODE.convert('PROI+E/NAI')
      assert_equal "τῷ", BETA_CODE.convert('TW=|')
      # TODO: implement macron and brevis support
      #assert_equal "μαχαίρᾱς", BETA_CODE.convert('MAXAI/RA%26S')
      #assert_equal "μάχαιρᾰ", BETA_CODE.convert('MA/XAIRA%27')
     end
  end
end
