# encoding: UTF-8
#--
#
# Copyright 2013 University of Oslo
# Copyright 2013 Marius L. Jøhndal
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
  module PresentationObjects
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def presentation_on(parent = nil, first_visible_method = 'first?', last_visible_method = 'last?')
        class_eval <<-EOV
          include ::Proiel::PresentationObjects::InstanceMethods

          def presentation_parent
            #{parent}
          end

          def presentation_first_visible?
            #{first_visible_method}
          end

          def presentation_last_visible?
            #{last_visible_method}
          end
        EOV
      end
    end

    module InstanceMethods
      # Returns all presentation text before the object (including presentation
      # text parent objects, if any). If there is no presentation text, the
      # function returns an empty string.
      def all_presentation_before
        p = []
        p << presentation_parent.all_presentation_before if presentation_parent and presentation_first_visible?
        p << presentation_before
        p.join
      end

      # Returns all presentation text after the object (including presentation
      # text from parent objects, if any). If there is no presentation text, the
      # function returns an empty string.
      def all_presentation_after
        p = []
        p << presentation_after
        p << presentation_parent.all_presentation_after if presentation_parent and presentation_last_visible?
        p.join
      end
    end
  end
end

ActiveRecord::Base.send(:include, Proiel::PresentationObjects)
