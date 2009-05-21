#!/usr/bin/env ruby
#
# positional_tag.rb - Positional tag functions
#
# Written by Marius L. Jøhndal, 2007, 2008
#

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

    # Returns an integer, -1, 0 or 1, suitable for sorting the tag.
    def <=>(o)
      self.to_s <=> o.to_s
    end

    # Returns the positional tag as a string.
    def to_s
      fields.collect { |field| self[field] }.join
    end

    # Returns +true+ if the tag is empty, i.e. uninitialised.
    def empty?
      keys.length == 0
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
        fields.zip(o.split('')).each { |e| self[e[0]] = e[1].to_sym if e[1] != '-' }
      when Hash, PositionalTag
        self.keys.each { |k| self.delete(k) }
        o.each_pair { |k, v| self[k.to_sym] = v unless v == '-' }
      else
        raise ArgumentError, "must be a String or PositionalTag"
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
