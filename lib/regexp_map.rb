#!/usr/bin/env ruby
#
# regexp_map.rb - Regexp based mapping of strings
#
# $Id: $
#
require 'delegate'

class RegexpMap
  def self.[](values)
    self.new(values)
  end

  def initialize(values)
    @mapping = {}
    values.each_pair do |k, v|
      self[k] = v   
    end
  end

  def []=(k, v)
    @mapping[Regexp.new(k)] = v
  end

  def match!(s)
    @mapping.each_pair do |regexp, substitution|
      s.gsub!(regexp, substitution)
    end
  end

  def match(s)
    @mapping.each_pair do |regexp, substitution|
      s = s.gsub(regexp, substitution)
    end
    s
  end
end
