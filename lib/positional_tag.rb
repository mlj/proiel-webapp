# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

# A positional tag.
class PositionalTag
  include Comparable
  include Enumerable

  # Creates a new positional tag object. The new object may
  # have a new value +o+ assigned to it. The new value may
  # be a string, another positional tag object or a hash.
  def initialize(o = nil)
    @values = Hash.new
    @values.default = '-'
    self.value = o if o
  end

  # Returns an integer, -1, 0 or 1, suitable for sorting the tag.
  def <=>(o)
    to_s <=> o.to_s
  end

  # Returns the positional tag as a string.
  def to_s
    fields.collect { |field| @values[field] }.join
  end

  # Returns +true+ if the tag is empty, i.e. uninitialised.
  def empty?
    @values.keys.length == 0
  end

  # Tests if the positional tag is contradicted by another positional tag. The
  # other positional tag may be a string or a positional tag object.
  def contradicts?(other)
    other = self.class.new(other) if other.is_a?(String)
    fields.any? { |f| @values[f] != '-' and other[f] != '-' and @values[f] != other[f] }
  end

  # Assigns a new value to the positional tag. The new value
  # may be a string, another positional tag object or a hash.
  def value=(o)
    case o
    when String
      fields.zip(o.split('')).each do |e|
        if e[1] == '-' or e[1].nil?
          @values.delete(e[0])
        else
          @values[e[0]] = e[1].to_sym
        end
      end
    when Hash, PositionalTag
      @values.keys.each { |k| @values.delete(k) }
      o.to_hash.each_pair { |k, v| @values[k.to_sym] = v unless v == '-' }
    else
      raise ArgumentError, "must be a String or PositionalTag"
    end
  end

  def to_hash
    @values
  end

  def [](field)
    @values[field]
  end

  # Assigns a new value to a field.
  def []=(field, value)
    raise ArgumentError, "invalid field #{field}" unless fields.include?(field.to_sym)

    if value == '-' or value.nil?
      @values.delete(field.to_sym)
    else
      @values.store(field.to_sym, value)
    end
  end

  def method_missing(method_name, *args)
    if fields.include?(method_name)
      if args.empty?
        @values[method_name]
      else
        raise ArgumentError, 'accessor does not take any arguments'
      end
    else
      super
    end
  end

  # Returns the positional tag as a string.
  def tag
    self.to_s
  end

  def each(&block)
    @values.each(&block)
  end
end
