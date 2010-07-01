#!/usr/bin/env ruby
#
# positional_tag.rb - Positional tag functions
#
# Written by Marius L. Jøhndal, 2007, 2008
#

# A positional tag.
class PositionalTag
  include Comparable

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
    raise ArgumentError, 'first argument must be a subclass of PositionalTag' unless klass.superclass == PositionalTag

    s = values.inject { |m, n| self.union_s(m.to_s, n.is_a?(String) ? n : n.to_s) }
    klass.new(s)
  end

  # Returns the `intersection' of a list of positional tags.
  # The positional tags may be PositionalTag objects or strings.
  # The intersection will be returned as a new object of class +klass+,
  # which must be a subclass of PositionalTag.
  def self.intersection(klass, *values)
    raise ArgumentError, 'first argument must be a subclass of PositionalTag' unless klass.superclass == PositionalTag

    s = values.inject { |m, n| self.intersection_s(m.to_s, n.is_a?(String) ? n : n.to_s) }
    klass.new(s)
  end

  # Returns the `union' of the positional tag and one or more other
  # positional tags. The other positional tags may be PositionalTag
  # objects or strings. The function raises an exception should
  # there be a conflict in one of the fields.
  def union(*values)
    PositionalTag::union(self.class, self, *values)
  end

  # Returns the `intersection' of the positional tag and one or more other
  # positional tags. The other positional tags may be PositionalTag
  # objects or strings.
  def intersection(*values)
    PositionalTag::intersection(self.class, self, *values)
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

  def tag=(o)
    self.value = o
  end
end
