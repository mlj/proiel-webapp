#!/usr/bin/env ruby
#
# boundaries.rb - PROIEL source boundary detection
#
# Written by Marius L. Jøhndal, 2008.
#
require 'proiel/boundaries/diff'
require 'proiel/boundaries/gale_church'

module PROIEL
  def self.detect_sentence_boundaries(a, b, writer, method)
    case method
    when :diff
      PROIEL::SentenceBoundaries::diff(a, b, writer)
    when :gale_church
      PROIEL::SentenceBoundaries::gale_church(a, b, writer)
    else
      raise ArgumentError.new("Unknown method #{method}")
    end
  end
end
