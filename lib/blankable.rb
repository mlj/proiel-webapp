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
  # Methods for blankable attributes, i.e. attributes whose value as nil or
  # empty string are equivalent and should be stored preferentially as NULL in
  # the database.
  #
  # Note that a sequence of spaces (or anything else that Rails' +blank?+
  # function might return true for) is not considered equivalent to nil by these
  # methods.
  module BlankableObjects
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def blankable_attributes(*attributes)
        self.cattr_accessor :blankable_attributes
        self.blankable_attributes = attributes.map(&:to_sym)

        class_eval <<-EOV
          include ::Proiel::BlankableObjects::InstanceMethods

          before_validation :before_validation_cleanup
        EOV
      end
    end

    module InstanceMethods
      def before_validation_cleanup
        self.blankable_attributes.each do |field|
          self.send("#{field}=", nil) if self.send(field).nil? or self.send(field) == ''
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Proiel::BlankableObjects)
