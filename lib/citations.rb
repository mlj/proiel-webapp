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

          PROIEL::Citations.citation_make_range(tw.first.try(:citation_part),
                                                tw.last.try(:citation_part))
        else
          citation_part == '' ? nil : citation_part
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Proiel::CitationsOnObjects)
