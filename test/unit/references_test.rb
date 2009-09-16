require File.dirname(__FILE__) + '/../test_helper'

class ReferencesTestCase < ActiveSupport::TestCase
  include References

  def test_serialisation
    assert_equal "", serialize_reference({})
    assert_equal "verse=1", serialize_reference({ "verse" => "1" })
    assert_equal "verse=1", serialize_reference({ "verse" => 1 })

    assert_equal "verse=10-26", serialize_reference({ "verse" => 10..26 })

    # Arrays with complete range
    assert_equal "verse=1-2", serialize_reference({ "verse" => [1, 2] })
    assert_equal "verse=1-2", serialize_reference({ "verse" => ["1", "2"] })
    assert_equal "verse=1-4", serialize_reference({ "verse" => [1, 2, 3, 4] })
    assert_equal "verse=1-4", serialize_reference({ "verse" => ["1", "2", "3", "4"] })
    assert_equal "verse=1-4", serialize_reference({ "verse" => [1, "2", 3, "4"] })

    # Mixed types in array with incomplete range
    assert_equal "verse=[1-3-4]", serialize_reference({ "verse" => [1, 3, "4"] })

    # Mixed types that cannot be coerced
    assert_equal "verse=[1-prol.]", serialize_reference({ "verse" => [1, "prol."] })

    assert_raise ArgumentError do
      serialize_reference({ "verse" => "[6,7]" })
    end

    assert_raise ArgumentError do
      serialize_reference({ "verse" => "foo-bar" })
    end

    assert_raise ArgumentError do
      serialize_reference({ "verse" => "[foo]" })
    end

    assert_raise ArgumentError do
      serialize_reference({ "verse" => "f=bar" })
    end
  end

  def test_unserialisation
    assert_equal({}, unserialize_reference(""))
    assert_equal({ "verse" => 1 }, unserialize_reference("verse=1"))
    assert_equal({ "verse" => "prol." }, unserialize_reference("verse=prol."))
    assert_equal({ "verse" => 1..2 }, unserialize_reference("verse=1-2"))
    assert_equal({ "verse" => 1..4 }, unserialize_reference("verse=1-4"))
    assert_equal({ "verse" => [1, 3, 4] }, unserialize_reference("verse=[1-3-4]"))
    assert_equal({ "verse" => [1, "prol."] }, unserialize_reference("verse=[1-prol.]"))
  end

  class Mock
    attr_accessor :r

    include References

    def reference_fields
      @r
    end
  end

  def test_last_of_reference_fields
    m = Mock.new

    m.r = { "verse" => 1 }
    assert_equal({ "verse" => 1 }, m.last_of_reference_fields)

    m.r = { "verse" => "prol." }
    assert_equal({ "verse" => "prol." }, m.last_of_reference_fields)

    m.r = { "verse" => 1..2 }
    assert_equal({ "verse" => 2 }, m.last_of_reference_fields)

    m.r = { "verse" => 1..4 }
    assert_equal({ "verse" => 4 }, m.last_of_reference_fields)

    m.r = { "verse" => [1, 3, 4] }
    assert_equal({ "verse" => 4 }, m.last_of_reference_fields)

    m.r = { "verse" => [1, "prol."] }
    assert_equal({ "verse" => "prol." }, m.last_of_reference_fields)
  end
end
