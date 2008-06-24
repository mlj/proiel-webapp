#!/usr/bin/env ruby

require 'test/unit'
require 'proiel/positional_tag'

class MyPositionalTag < Logos::PositionalTag
  def fields
    [:a, :b, :c, :d]
  end
end

class PositionalTagTestCase < Test::Unit::TestCase
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

  def test_union_class_method
    x = MyPositionalTag.new('D---')
    y = MyPositionalTag.new('-f-p')
    z = MyPositionalTag.new('---p')
    assert_equal 'Df-p', Logos::PositionalTag::union(MyPositionalTag, x, y, z).to_s
  end

  def test_union
    x = MyPositionalTag.new('D---')
    y = MyPositionalTag.new('-f-p')
    z = MyPositionalTag.new('---p')
    assert_equal 'Df-p', x.union(y, z).to_s
  end

  def test_union!
    x = MyPositionalTag.new('D---')
    y = MyPositionalTag.new('-f-p')
    z = MyPositionalTag.new('---p')
    x.union!(y, z)
    assert_equal 'Df-p', x.to_s
  end

  def test_intersection_class_method
    x = MyPositionalTag.new('D--p')
    y = MyPositionalTag.new('-f-p')
    z = MyPositionalTag.new('---p')
    assert_equal '---p', Logos::PositionalTag::intersection(MyPositionalTag, x, y, z).to_s
  end

  def test_intersection
    x = MyPositionalTag.new('D--p')
    y = MyPositionalTag.new('-f-p')
    z = MyPositionalTag.new('---p')
    assert_equal '---p', x.intersection(y, z).to_s
  end

  def test_intersection!
    x = MyPositionalTag.new('D--p')
    y = MyPositionalTag.new('-f-p')
    z = MyPositionalTag.new('---p')
    x.intersection!(y, z)
    assert_equal '---p', x.to_s
  end

  def test_contradicts?
    assert_equal true,  MyPositionalTag.new('xyz-').contradicts?('xz-v')
    assert_equal false, MyPositionalTag.new('xyz-').contradicts?('xy-v')
  end
end
