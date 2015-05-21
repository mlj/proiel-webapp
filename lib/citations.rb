# encoding: UTF-8
#--
#
# Copyright 2011, 2012, 2013 University of Oslo
# Copyright 2011, 2012, 2013 Marius L. Jøhndal
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

module Proiel
  module CitationsOnObjects
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Adds the instance methods +citation+ and +citation_without_source+ to
      # an object. The object must implement +source_citation_part+ for
      # accessing the +citation_part+ attribute of the source that the object
      # belongs to. The object may implement +tokens_with_citation+ for
      # generating a Relation object with all dependent tokens with a non-blank
      # +citation_part+. If it does not implement this method, the object's own
      # +citation_part+ attribute will be accessed instead.
      def citation_on
        class_eval <<-EOV
          include ::Proiel::CitationsOnObjects::InstanceMethods
        EOV
      end
    end

    module InstanceMethods
      # Returns the citation for the object computed from all dependent objects
      # and from the source that the object belongs to.
      def citation
        [source_citation_part, citation_without_source].compact.join(' ')
      end

      # Returns the citation for the object computed from all dependent objects
      # but without the source prefix. If no citation can be computed because
      # there are no dependents, or if all citation_part values on dependents
      # are nil or an empty string, nil is returned.
      def citation_without_source
        if respond_to?(:tokens_with_citation)
          tw = tokens_with_citation

          Proiel::citation_make_range(tw.first.try(:citation_part),
                                      tw.last.try(:citation_part))
        else
          citation_part == '' ? nil : citation_part
        end
      end
    end
  end

  def self.citation_make_range(cit1, cit2)
    raise ArgumentError unless cit1.is_a?(String) or cit1.is_a?(NilClass)
    raise ArgumentError unless cit2.is_a?(String) or cit1.is_a?(NilClass)

    # Remove any nil and empty-string citation, and reduce a range that starts
    # and ends with the same citation to a single citation.
    c = [cit1, cit2].reject(&:blank?).uniq

    case c.length
    when 0
      nil
    when 1
      c.first
    else
      [cit1, citation_strip_prefix(cit1, cit2)].join("\u{2013}")
    end
  end

  # Returns +cit2+ with the longest common prefix in +cit1+ and +cit2+ stripped
  # off. Not any string is considered a common prefix; the regular expression
  # +dividers+ is used to chunk +cit1+ and +cit2+, and the chunks are compared
  # as possible prefixes.
  #
  # For example, with +dividers+ set to whitespace and a period:
  #
  #   citation_strip_prefix('Matt 5.16', 'Matt 5.27') # => "27"
  #   citation_strip_prefix('Matt 5.26', 'Matt 5.27') # => "27"
  #   citation_strip_prefix('Matt 4.13', 'Matt 5.27') # => "5.27"
  #
  def self.citation_strip_prefix(cit1, cit2, dividers = /([\s\.]+)/u)
    raise ArgumentError unless cit1.is_a?(String)
    raise ArgumentError unless cit2.is_a?(String)

    # Chunk cit1 and cit2
    x = cit1.split(dividers)
    y = cit2.split(dividers)

    # Interleave x and y but compensate for zip's behaviour when y.length < x.length
    zipped = x.length >= y.length ? x.zip(y) : y.zip(x).map(&:reverse)

    zipped.inject('') do |d, (a, b)|
      if not d.empty? or a != b
        d + (b || '')
      else
        ''
      end
    end
  end
end

ActiveRecord::Base.send(:include, Proiel::CitationsOnObjects)
