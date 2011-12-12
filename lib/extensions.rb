#!/usr/bin/env ruby

class Hash
  alias :map :collect

  # An inverted reject
  # TODO: rename to select as Array#select
  def accept
    reject { |k, v| not yield(k, v) }
  end

  def collect
    r = []
    each_pair { |key, value| r << yield(key, value) }
    r
  end

  # Returns a new hash with only those key-value pairs that correspond to the given keys.
  # [Equivalent to Hash#slice in Facets but with messy Rails adapatations]
  def slice(*k)
    h = {}
    if defined? HashWithIndifferentAccess and self.is_a? HashWithIndifferentAccess
      k.each { |key| self.has_key?(key) ? h[key] = self[key] : h[key] = self.default }
    else
      k.each { |key| h[key] = fetch(key) if self.has_key?(key) }
    end
    h
#    k.inject({}) { |h, key| h[key] = fetch(key); h } # non-rails
  end
end

class Array
  def to_h
    Hash[*self.flatten]
  end

  def product(*enums)
    enums.unshift self
    result = [[]]
    while [] != enums
      t, result = result, []
      b, *enums = enums
      t.each do |a|
        b.each do |n|
          result << a + [n]
        end
      end
    end
    result
  end
end

if $0 == __FILE__
  require 'test/unit'

  class TestExtensionsCase < Test::Unit::TestCase
    def test_to_proc
      assert_equal [:sdfgsdfg, :foo, :bazar, :bara], %w'sdfgsdfg foo bazar bara'.map(&:to_sym)
    end

    def test_to_h
      h = { :a => 1, :b => 2, :c => 3 }
      assert_equal h, Array[[:b, 2], [:a, 1], [:c, 3]].to_h
    end

    def test_hash_slice
      assert_equal Hash[:foo => 4, :bar => 8], Hash[:bar => 8, :daz => 9, :diz => 6, :foo => 4].slice(:foo, :bar)
    end
  end
end
