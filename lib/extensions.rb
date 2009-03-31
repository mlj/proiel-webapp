#!/usr/bin/env ruby
#
# extensions.rb - Core extensions
#
# Written by Marius L. Jøhndal <mariuslj at ifi.uio.no>, 2008
#
class Object
  def tap
    yield self
    self
  end if RUBY_VERSION < '1.8.7'

  def using(object, &block)
    object.instance_eval(&block)
    object
  end

  # K combinator
  #
  # Examples
  #
  # def foo
  #   returning [] { |values| values << 'foo' }
  # end
  #
  # Is defined in Rails/Active Support.
  def returning(value)
    yield(value)
    value
  end unless defined?(ActiveSupport)
end

module Kernel
  # http://ola-bini.blogspot.com/2006/09/ruby-metaprogramming-techniques.html
  # http://www.rcrchive.net/rcr/show/231
  def singleton_class
    class << self; self; end
  end
end

class Numeric
  def prec(x)
    sprintf("%.*f", x, self).to_f
  end
end

class Symbol
  def to_proc
    Proc.new { |*args| args.shift.__send__(self, *args) }
  end if RUBY_VERSION < '1.8.7' and not :test.respond_to?(:to_proc)

  def humanize
    to_s.humanize
  end unless defined?(ACTIVE_RECORD)

  alias :humanise :humanize unless defined?(ACTIVE_RECORD)
end

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

  # Modifies a key in a hash, while keeping the associated value the
  # same.
  #
  # If two keys are given, then the second key is changed to
  # the first.
  #
  #   foo = { :a => 1, :b => 2 }
  #   foo.rekey('a', :a)       #=> { 'a' => 1, :b => 2 }
  #   foo.rekey('b', :b)       #=> { :a => 1, 'b' => 2 }
  #   foo.rekey('foo', 'bar')  #=> { :a => 1, :b => 2 }
  #
  # If a block is given, converts all keys in the Hash accroding
  # to the given block. If the block returns +nil+ for given key,
  # then that key will be left intact.
  #
  #   foo = { :name => 'Gavin', :wife => :Lisa }
  #   foo.rekey { |k| k.to_s }  #=>  { "name" => "Gavin", "wife" => :Lisa }
  #
  # [Equivalent to Hash#rekey in Facets]
  def rekey(*args, &block)
    dup.rekey!(*args, &block)
  end

  # Synonym for Hash#rekey, but modifies the receiver in place (and returns it).
  def rekey!(*args, &block)
    if args.empty?
      block = lambda { |k| k.to_sym} unless block
      keys.each do |k|
        nk = block[k]
        self[nk] = delete(k) if nk
      end
    else
      raise ArgumentError, "3 for 2" if block
      to, from = *args
      self[to] = self.delete(from) if self.has_key?(from)
    end
    self
  end

  # Returns a new hash identical to the original one except for
  # the key-value pairs identified by the keys +less_keys+.
  #
  # Identical to Facets' Hash#except.
  def except(*less_keys)
    slice(*keys - less_keys)
  end

  # Verbatim from ActiveSupport::CoreExtensions::Hash::Keys (2.0.1)
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten
    raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}") unless unknown_keys.empty?
  end unless defined?(ActiveSupport)

  # Verbatim from ActiveSupport::CoreExtensions::Hash::ReverseMerge (2.0.1)
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end unless defined?(ActiveSupport)

  # Verbatim from ActiveSupport::CoreExtensions::Hash::ReverseMerge (2.0.1)
  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end unless defined?(ActiveSupport)
end

module Enumerable
  def find_repetitions
    select { |e| index(e) != rindex(e) }.uniq
  end

  def classify(&block)
    inject({}) { |k, e| (k[block.call(e)] ||= []) << e; k }
  end

  def inject_with_index(injected)
    each_with_index { |e, i| injected = yield injected, e, i }
    injected
  end
end

class Array
  def to_h
    Hash[*self.flatten]
  end

  def tail
    h, *t = self
    t
  end

  def head
    first
  end

  def invert
    inject_with_index({}) { |k, e, i| k[e] = i; k }
  end

  def shuffle
    sort { rand(3) - 1 }
  end if RUBY_VERSION < '1.8.7'
end

class String
  def wrap(columns = 80, indentation = 0)
    # http://blog.macromates.com/2006/wrapping-text-with-regular-expressions/
    gsub(/(.{1,#{columns}})( +|$)\n?|(.{#{columns}})/, " " * indentation + "\\1\\3\n")
  end

  # Returns the longest prefix that this string and the string +s+ has in common.
  # The length of the prefix can be limited by supplying +max+.
  #
  # Example
  #   "foobar".common_prefix("foobaz")    # "fooba"
  #   "foobar".common_prefix("foobaz", 3) # "foo"
  #   "foobar".common_prefix("bazfoo", 3) # "" 
  #
  def common_prefix(s, max = nil)
    l1, l2 = self.size, s.size
    min = l1 < l2 ? l1 : l2
    min = min < max ? min : max if max
    min.times do |i|
      return self.slice(0, i) if self[i] != s[i]
    end
    return self.slice(0, min)
  end

  # Capitalizes the first word and turns underscores into spaces.
  #
  # Examples
  #   "employee_salary" #=> "Employee salary"
  def humanize
    gsub(/_id$/, "").gsub(/_/, " ").capitalize
  end unless defined?(ACTIVE_RECORD)

  alias :humanise :humanize unless defined?(ACTIVE_RECORD)
end

#FIXME: where should this go?
def clamp(i, a, b)
  (i < a ? a : (i > b ? b : i))
end

class Range
  # Combines two ranges.
  #
  # Stolen from Facets' Range#combine.
  def self.combine(*intervals)
    intype = intervals.first.class
    result = []

    intervals = intervals.collect do |i|
      [i.first, i.last]
    end

    intervals.sort.each do |(from, to)|
      if result.empty? or from > result.last[1]
        result << [from, to]
      elsif to > result.last[1]
        result.last[1] = to
      end
    end

    if intype <= Range
      result.collect{ |i| ((i.first)..(i.last)) }
    else
      result
    end
  end

  def combine(*intervals)
    Range.combine(self, *intervals)
  end

  def overlap?(o)
    include?(o.first) or o.include?(first)
  end
end

if $0 == __FILE__
  require 'test/unit'

  class EnumerableExtensionTestCase < Test::Unit::TestCase
    def test_find_repetitions
      assert_equal ['x', 'y'], %w'a b c d e x f g x h i j k l y y m n'.find_repetitions
    end
  end

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

    def test_head
      assert_equal 1, Array[1, 2, 3, 4, 5].head
      assert_equal nil, Array[].head
    end

    def test_tail
      assert_equal [2, 3, 4, 5], Array[1, 2, 3, 4, 5].tail
      assert_equal [], Array[].tail
    end

    def test_count
      assert_equal Hash[:foo => 2, :bar => 5], 
        [:foo, :bar, :bar, :foo, :bar, :bar, :bar].count
    end

    def test_classify
      assert_equal Hash[:odd => [1, 3, 5, 7], :even => [2, 4, 6]], 
        [1, 2, 3, 4, 5, 6, 7].classify { |x| x % 2 == 0 ? :even : :odd }
    end

    def test_inject_with_index
      assert_equal 11 + 100 * 0 + 5 * 1 + 7 * 2 + 9 * 3, [100, 5, 7, 9].inject_with_index(11) { |sum, e, i| sum += e * i }
    end

    def test_array_invert
      assert_equal Hash[:foo => 2, :bar => 0, :daz => 1], [:bar, :daz, :foo].invert
    end

    def test_common_prefix
      assert_equal "fooba", "foobar".common_prefix("foobaz") # fooba
      assert_equal "foo", "foobar".common_prefix("foobaz", 3) # "foo"
      assert_equal "", "foobar".common_prefix("bazfoo", 3) # "" 
    end

    def test_rekey
      foo =     { :a => 1,  :b => 2 }
      expect1 = { 'a' => 1, :b => 2 }
      expect2 = { :a => 1,  'b' => 2 }

      assert_equal foo, foo.rekey('foo', 'bar')

      assert_equal expect1, foo.rekey('a', :a)
      assert_equal expect2, foo.rekey('b', :b)
  
      foo = { :name => 'Gavin', :wife => :Lisa }
      expect = { "name" => "Gavin", "wife" => :Lisa }
      assert_equal expect, foo.rekey { |k| k.to_s }
    end

    def test_rekey!
      foo =     { :a => 1,  :b => 2 }
      expect1 = { 'a' => 1, :b => 2 }
      expect2 = { 'a' => 1,  'b' => 2 }

      foo.rekey!('foo', 'bar')
      assert_equal foo, foo

      foo.rekey!('a', :a)
      assert_equal expect1, foo

      foo.rekey!('b', :b)
      assert_equal expect2, foo
  
      foo = { :name => 'Gavin', :wife => :Lisa }
      foo.rekey! { |k| k.to_s }
      expect = { "name" => "Gavin", "wife" => :Lisa }
      assert_equal expect, foo
    end
  end
end
