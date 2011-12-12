require File.dirname(__FILE__) + '/../test_helper'

class MyPositionalTag < PositionalTag
  def fields
    [:a, :b, :c, :d]
  end
end

class PositionalTagTestCase < ActiveSupport::TestCase
  def test_new_and_to_s
    x = MyPositionalTag.new('D---')
    assert_equal 'D---', x.to_s

    y = MyPositionalTag.new(x)
    assert_equal 'D---', x.to_s
    assert_equal 'D---', y.to_s

    z = MyPositionalTag.new({ :a => 'D' })
    assert_equal 'D---', z.to_s
  end

  def test_accessors
    x = MyPositionalTag.new('D---')
    assert_equal :D, x.a

    assert_raises ArgumentError do
      x.a(4, 5)
    end

    assert_raises NoMethodError do
      x.k
    end
  end

  def test_uninitialised_fields
    x = MyPositionalTag.new
    assert_equal '----', x.to_s
  end

  def test_equality
    a = MyPositionalTag.new('Nb-s')
    b = MyPositionalTag.new('Nb-s')
    assert_equal true, a == b

    a = MyPositionalTag.new('Nb-s')
    b = MyPositionalTag.new('N--s')
    assert_equal false, a == b
  end

  def test_contradicts?
    assert_equal true,  MyPositionalTag.new('xyz-').contradicts?('xz-v')
    assert_equal false, MyPositionalTag.new('xyz-').contradicts?('xy-v')
  end

  def test_comparison
    x = MyPositionalTag.new('Px--')
    y = MyPositionalTag.new('A---')
    assert_equal 1, x <=> y
    assert_equal 0, x <=> x
    assert_equal -1, y <=> x
  end

  def test_empty?
    x = MyPositionalTag.new('Px--')
    y = MyPositionalTag.new('----')
    assert_equal false, x.empty?
    assert_equal true, y.empty?

    x[:a], x[:b] = nil, nil
    assert_equal true, x.empty?

    y[:a], y[:b] = 'x', 'y'
    assert_equal false, y.empty?
  end
end
