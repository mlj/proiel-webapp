#!/usr/bin/env ruby
#
# positional_tag.rb - Positional tag functions
#
# Written by Marius L. Jøhndal, 2007, 2008
#
require 'xmlsimple'

module Logos
  # A positional tag.
  class PositionalTag < Hash
    # Creates a new positional tag object. The new object may
    # have a new value +value+ assigned to it. The new value may
    # be a string, another positional tag object or a hash.
    def initialize(value = nil)
      self.default = '-'
      self.value = value if value
    end

    # Tests if the positional tag has the same value as another positional tag
    # +other+.
    def ==(other)
      self.to_s == other.to_s
    end

    # Returns the positional tag as a string.
    def to_s
      fields.collect { |field| self[field] }.join
    end

    # Tests if the positional tag is contradicted by another positional tag. The
    # other positional tag may be a string or a positional tag object.
    def contradicts?(other)
      other = self.class.new(other) if other.is_a?(String)
      fields.any? { |f| self[f] != '-' and other[f] != '-' and self[f] != other[f] }
    end

    # Computes the `intersection' of two positional tags on string form.
    def self.intersection_s(a, b)
      raise ArgumentError, "Positional tags have different length: #{a.length} != #{b.length}" unless a.length == b.length

      a.split('').zip(b.split('')).collect do |x, y|
        x == y ? x : '-'
      end.join('')
    end

    # Computes the `union' of two positional tags on string form.
    # Raises an exceptions if there is a conflict over the
    # value of any of the fields.
    def self.union_s(a, b)
      raise ArgumentError, "Positional tags have different length: #{a.length} != #{b.length}" unless a.length == b.length

      a.split('').zip(b.split('')).collect do |x, y| 
        if x == '-'
          y
        elsif y != '-' and x != y
          raise ArgumentError, "Union undefined; field values conflict"
        else
          x
        end
      end.join('')
    end

    # Returns the `union' of a list of positional tags.
    # The positional tags may be PositionalTag objects or strings. 
    # The union will be returned as a new object of class +klass+,
    # which must be a subclass of PositionalTag.
    # The function raises an exception should there be a conflict 
    # in one of the fields.
    def self.union(klass, *values)
      raise ArgumentError, 'first argument must be a subclass of Logos::PositionalTag' unless klass.superclass == Logos::PositionalTag

      s = values.inject { |m, n| self.union_s(m.to_s, n.is_a?(String) ? n : n.to_s) }
      klass.new(s)
    end

    # Returns the `intersection' of a list of positional tags.
    # The positional tags may be PositionalTag objects or strings. 
    # The intersection will be returned as a new object of class +klass+,
    # which must be a subclass of PositionalTag.
    def self.intersection(klass, *values)
      raise ArgumentError, 'first argument must be a subclass of Logos::PositionalTag' unless klass.superclass == Logos::PositionalTag

      s = values.inject { |m, n| self.intersection_s(m.to_s, n.is_a?(String) ? n : n.to_s) }
      klass.new(s)
    end

    # Returns the `union' of the positional tag and one or more other
    # positional tags. The other positional tags may be PositionalTag 
    # objects or strings. The function raises an exception should
    # there be a conflict in one of the fields.
    def union(*values)
      Logos::PositionalTag::union(self.class, self, *values)
    end

    # Returns the `intersection' of the positional tag and one or more other
    # positional tags. The other positional tags may be PositionalTag 
    # objects or strings.
    def intersection(*values)
      Logos::PositionalTag::intersection(self.class, self, *values)
    end

    # Updates the positional tag with the `union' of the positional tag
    # and one or more other positional tags. The other positional tags
    # may be PositionalTag objects or strings. The function raises
    # an expection should there be a conflict in one of the fields.
    def union!(*values)
      self.value = union(*values)
    end

    # Updates the positional tag with the `intersection' of the positional tag
    # and one or more other positional tags. The other positional tags
    # may be PositionalTag objects or strings.
    def intersection!(*values)
      self.value = intersection(*values)
    end

    # Assigns a new value to the positional tag. The new value
    # may be a string, another positional tag object or a hash.
    def value=(o)
      case o
      when String
        fields.zip(o.split('')).each { |e| self[e[0]] = e[1].to_sym if e[1] != '-' }
      when Hash, Logos::PositionalTag
        self.keys.each { |k| self.delete(k) }
        o.each_pair { |k, v| self[k.to_sym] = v unless v == '-' }
      else
        raise ArgumentError, "must be a String or Logos::PositionalTag"
      end
    end

    # Assigns a new value to a field.
    def []=(field, value)
      raise ArgumentError, "invalid field #{field}" unless fields.include?(field.to_sym)

      if value == '-' or value.nil?
        delete(field.to_sym)
      else
        store(field.to_sym, value)
      end
    end

    def method_missing(method_name, *args)
      if fields.include?(method_name)
        if args.empty?
          self[method_name]
        else
          raise ArgumentError, 'accessor does not take any arguments'
        end
      else
        super
      end
    end
  end
end

if $0 == __FILE__
  require 'test/unit'

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
end
