#!/usr/bin/env ruby
#
# ucodes.rb - Unicode code point constants and character class helpers
#
# Written by Marius L. Jøhndal, 2008.
#
module Unicode
  CONSTANT_REGEXP = /^U([0-9a-fA-F]{4,5}|10[0-9a-fA-F]{4})$/.freeze

  # Defines Unicode code point constants of the form Uxxxx for all Unicode
  # codepoints from U0000 to U10FFFF. The value of each constant is the
  # UTF-8 string for the codepoint.
  #
  # Examples:
  #   copyright = Unicode::U00A9
  #   euro = Unicode::U20AC
  #   infinity = Unicode::U221E
  #
  # Derived from code from http://www.davidflanagan.com/blog/2007_08.html.
  #
  def self.const_missing(name)
    if name.to_s =~ CONSTANT_REGEXP
      const_set(name, [$1.to_i(16)].pack("U").freeze)
    else
      raise NameError, "Uninitialized constant: Unicode::#{name}"
    end
  end

  # Returns a regular expression that matches all the Unicode characters
  # in the array +characters+.
  def self.make_character_class(characters)
    r = characters.collect { |c| /#{c}/u }
    Regexp.union(*r)
  end
end

if $0 == __FILE__
  $KCODE = 'u'

  require 'test/unit'

  class ConstantsTestCase < Test::Unit::TestCase
    def test_regular_access
      assert_equal "©", Unicode::U00A9
      assert_equal "€", Unicode::U20AC
    end

    def test_indirect_access
      assert_equal "€", Unicode.const_get(:U20AC)
    end

    def test_undefined_access
      assert_raise NameError do
        Unicode::U20FFFF
      end
    end
  end
end

