#!/usr/bin/env ruby
#
# frequency_tabulation.rb -
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
require 'forwardable'

# The implementation internally relies on hashes, so any object to be
# counted should provide the eql? and hash functions to ensure that
# unique keys are generated.
class FrequencyTabulation
  extend Forwardable

  def initialize
    @frequencies = Hash.new(0)
  end

  def inc(o, value = 1)
    raise "Object does not respond to eql? and hash" unless quacks?(o)

    @frequencies[o] ||= 0
    @frequencies[o] += value 
  end

  def dec(o, value = 1)
    self.inc(o, -value)
  end

  def_delegator :@frequencies, :sort
  def_delegator :@frequencies, :each_pair
  def_delegator :@frequencies, :empty?
  def_delegator :@frequencies, :[]

  # Returns the +n+ most frequent objects as pairs of
  # object and frequency.
  def most_frequent(n = 1)
    @frequencies.sort { |x, y| y[1] <=> x[1] }.first(n)
  end

  def size 
    @frequencies.keys.length
  end

  def inspect
    @frequencies.collect { |o, f| "#{o}: #{f}" }.join("\n")
  end

  private

  def quacks?(o)
    o.respond_to?(:eql?) and o.respond_to?(:hash)
  end
end

if $0 == __FILE__
  require 'test/unit'

  class FrequencyTabulationTestCase < Test::Unit::TestCase
    def test_counting
      ft = FrequencyTabulation.new

      assert_equal 0, ft['foo']
      assert_equal 0, ft['bar']

      ft.inc('foo')
      ft.inc('bar', 5)
      assert_equal 1, ft['foo']
      assert_equal 5, ft['bar']

      ft.inc('foo')
      assert_equal 2, ft['foo']
      assert_equal 5, ft['bar']

      ft.dec('bar', 3)
      assert_equal 2, ft['foo']
      assert_equal 2, ft['bar']
    end

    def test_length
      ft = FrequencyTabulation.new
      assert_equal 0, ft.size
      ft.inc('foo')
      assert_equal 1, ft.size
      ft.inc('bar', 5)
      ft.inc('foo')
      assert_equal 2, ft.size
    end

    def test_most_frequent
      ft = FrequencyTabulation.new
      ft.inc('a', 5)
      ft.inc('b', 2)
      ft.inc('c', 3)
      ft.inc('d', 8)
      assert_equal [['d', 8]], ft.most_frequent
      assert_equal [['d', 8]], ft.most_frequent(1)
      assert_equal [['d', 8], ['a', 5]], ft.most_frequent(2)
      assert_equal [], ft.most_frequent(0)
      assert_equal [['d', 8], ['a', 5], ['c', 3], ['b', 2]], ft.most_frequent(100)
    end
  end
end
