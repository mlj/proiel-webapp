#!/usr/bin/env ruby
#
# boundaries.rb - PROIEL source boundary detection
#
# Written by Marius L. Jøhndal, 2008.
#
require 'proiel/boundaries/diff'
require 'proiel/boundaries/gale_church'

module PROIEL
  # Tries to detect sentence boundaries in one source +a+ by
  # comparing it with another source +b+. The result is
  # written as a third source using a source writer +writer+.
  # The detection method is determined by +method+ and may
  # be one of
  #   +diff+: Run a diff algorithm that looks for punctuation
  #   in +b+ and attempts to detetct sentence boundaries
  #   in +a+ by placing the punctuation at correct places
  #   in +a+.
  #   +diff_include_punctuation+: As +diff+, but includes the
  #   punctuation in the final output.
  #   +gale_church+: Uses the Gale-Church alignment algorithm
  #   to align punctuation in +a+ and +b+ and transfers
  #   sentence boundaries from +a+ to +b+.
  def self.detect_sentence_boundaries(a, b, writer, method)
    case method
    when :diff
      PROIEL::SentenceBoundaries::diff(a, b, writer, :strip_punctuation => true)
    when :diff_add_punctuation
      PROIEL::SentenceBoundaries::diff(a, b, writer)
    when :gale_church
      PROIEL::SentenceBoundaries::gale_church(a, b, writer)
    else
      raise ArgumentError.new("Unknown method #{method}")
    end
  end
end
