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
      when Fixnum, String
        value = value.to_s
      when Array
        # FIXME: Merge consecutive numbers to ranges.
        value = value.join(',')
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
    r.map { |k, v| "#{k}=#{v}" }.join(',')
  end

  def unserialize_reference(r)
    r.split(',').inject({}) do |s, f|
      k, v = f.split('=')
      s[k] = v
      s
    end
  end

  private

  def reference_level
    self.class.to_s.underscore
  end
end
