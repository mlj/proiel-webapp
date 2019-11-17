# encoding: UTF-8
#--
#
# Copyright 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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
  module OrderedObjects
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def ordered_on(field, collection)
        self.cattr_accessor :ordered_on_field
        self.ordered_on_field = field.to_sym

        class_eval <<-EOV
          include ::Proiel::OrderedObjects::InstanceMethods

          def ordering_field
            #{field}
          end

          def ordering_collection
            #{collection}
          end
        EOV
      end
    end

    module InstanceMethods
      # Returns true if there is a previous object in the ordering.
      def has_previous?
        previous_objects.exists?
      end

      # Returns true if there is a next object in the ordering.
      def has_next?
        next_objects.exists?
      end

      def first?
        !has_previous?
      end

      def last?
        !has_next?
      end

      # Returns previous objects in the ordering. The objects are not necessarily
      # returned in order.
      def previous_objects
        ordering_collection.where("#{ordered_on_field} < ?", ordering_field)
      end

      # Returns next objects in the ordering. The objects are not necessarily
      # returned in order.
      def next_objects
        ordering_collection.where("#{ordered_on_field} > ?", ordering_field)
      end
    end
  end
end

ActiveRecord::Base.send(:include, Proiel::OrderedObjects)
