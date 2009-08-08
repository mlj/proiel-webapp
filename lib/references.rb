#--
#
# Copyright 2009 University of Oslo
# Copyright 2009 Marius L. Jøhndal
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

module References
  EN_DASH = Unicode::U2013

  # Returns a citation-form reference. This assumes that the attribute
  # +reference_fields+ and +reference_parent+ are defined and that
  # +reference_format+, +tracked_references+, +title+ and
  # +abbreviation+ are defined on the top reference level.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    reference_fields.merge({ :title => source_title(options) }).inject(reference_format_for_this_level) do |s, f|
      key, value = f

      case value
      when Range
        value = [value.first, value.last].join(EN_DASH)
      else
        raise "Invalid reference_fields value #{value.inspect} for key #{key}"
      end

      s.gsub("##{key}#", value)
    end
  end

  # Sets the reference fields. Also updates fields in parent levels,
  # which must be saved separately if updated.
  def reference_fields=(x)
    write_reference(x.slice(*tracked_references_on_this_level))
    reference_parent.reference_fields = x if reference_parent
  end

  # Returns the reference fields. Also merges in fields from parent
  # level.
  def reference_fields
    if reference_parent
      reference_parent.reference_fields.merge(read_reference)
    else
      read_reference
    end
  end

  protected

  # Returns the source title.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the title.
  def source_title(options = {})
    if reference_parent
      reference_parent.source_title(options)
    else
      options[:abbreviated] ? abbreviation : title
    end
  end

  def read_hierarchic_attribute(attr)
    if has_attribute?(attr)
      read_attribute(attr)
    elsif reference_parent
      reference_parent.read_hierarchic_attribute(attr)
    else
      raise ArgumentError, 'attribute not found'
    end
  end

  def reference_format_for_this_level
    read_hierarchic_attribute(:reference_format)[reference_level] || ""
  end

  def tracked_references_on_this_level
    read_hierarchic_attribute(:tracked_references)[reference_level]
  end

  def write_reference(r)
    write_attribute(:reference_fields, serialize_reference(r))
  end

  def read_reference
    unserialize_reference(read_attribute(:reference_fields))
  end

  def serialize_reference(r)
    r.map do |k, v|
      v = serialize_reference_value(v)
      "#{k}=#{v}"
    end.join(',')
  end

  RANGE_PATTERN = /^(\d+)-(\d+)$/
  ARRAY_PATTERN = /^\[(.*)\]$/

  def serialize_reference_value(v)
    # Do a bit of work here to reduce the amount of information and
    # keep things consistent
    case v
    when Range
      "#{serialize_reference_value(v.first)}-#{serialize_reference_value(v.last)}"
    when Array
      if v.length == 0
        raise ArgumentError, 'invalid empty array value in reference'
      elsif v.length == 1
        serialize_reference_value(v.first)
      else
        # Check if we are dealing with integers only, which is the
        # normal case.
        if v.map(&:to_i).map(&:to_s) == v.map(&:to_s)
          # Yes, convert to integers, sort and check to see if it is a
          # continuous range, in which case we swap to a range
          # representation on the format "x-y".
          v = v.map(&:to_i).sort
          v = "#{v.first}-#{v.last}" if (v.first..v.last).to_a == v
        end

        # If still an array, transpose to our array format, which is
        # [a,b,c] etc.
        v = "[#{v.join('-')}]" if v.is_a?(Array)

        v
      end
    when String
      raise ArgumentError, 'invalid value in reference' if v[/[,=-]/] or v[RANGE_PATTERN] or v[ARRAY_PATTERN]
      v
    when Integer
      # Pass through
      v
    else
      raise ArgumentError, "invalid value (#{v.class}) in reference"
    end
  end

  def unserialize_reference(r)
    r.split(',').inject({}) do |s, f|
      k, v = f.split('=')
      case v
      when RANGE_PATTERN
        v = (unserialize_reference_value($1))..(unserialize_reference_value($2))
      when ARRAY_PATTERN
        v = $1.split('-').map { |x| unserialize_reference_value(x) }
      else
        v = unserialize_reference_value(v)
      end
      s[k] = v
      s
    end
  end

  def unserialize_reference_value(v)
    if v.to_i.to_s == v
      v.to_i
    else
      v
    end
  end

  private

  def reference_level
    self.class.to_s.underscore
  end
end
