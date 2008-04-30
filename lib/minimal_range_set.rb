#!/usr/bin/env ruby
#
# minimal_range_set.rb - Utility class for computing the minimal set of non-overlapping
# ranges for a set of ranges
#
# Written by Marius L. Jøhndal, 2008
#
require 'extensions'

class MinimalRangeSet
  attr_reader :ranges

  def initialize
    @ranges = []
  end

  def add(o)
    accumulated_range = o.dup

    # We need to look for overlaps. Difficulty lies in the fact that the new
    # range may overlap with multiple existing ranges, and so those will have
    # to be merged. We do this by maintaining a running range accumulator which
    # we will add at the end. As we accumulate, we remove anything that overlaps.
    @ranges.reject! do |r|
      if r.overlap?(accumulated_range)
        # Recompute the accumulated range to contain both this range
        # and the accumulated one.
        f = Range.combine(accumulated_range, r)
        raise "Error combining ranges: multiple ranges returned #{f}: call #{accumulated_ranges}, #{r}" unless f.length == 1
        accumulated_range = f.first
        true
      else
        false
      end
    end

    @ranges << accumulated_range 
    @ranges.sort! { |x, y| x.first <=> y.first }
  end

  def to_s
    @ranges.collect { |r| r.to_s }.join(', ')
  end
end

if $0 == __FILE__
  require 'test/unit'

  class MinimalRangeSetTest < Test::Unit::TestCase
    def test_computation
      m = MinimalRangeSet.new
      m.add(1..1)
      m.add(1..1)
      m.add(1..2)
      m.add(2..2)
      m.add(2..2)
      m.add(3..3)
      m.add(4..4)
      m.add(5..6)
      m.add(7..7)
      m.add(1..1)
      m.add(1..1)
      m.add(2..2)
      m.add(2..2)
      m.add(2..2)
      m.add(3..3)
      m.add(4..5)
      m.add(6..7)
      assert_equal [1..2, 3..3, 4..7], m.ranges
    end
  end
end
