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
  # Returns a citation-form reference. This assumes that
  # +reference_fields+, +source_title+ and
  # +citation_format+ are accessible.
  #
  # ==== Options
  # <tt>:abbreviated</tt> -- If true, will use abbreviated form for the citation.
  def citation(options = {})
    reference_fields.merge({ :title => source_title(options) }).inject(citation_format) do |s, f|
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
end
