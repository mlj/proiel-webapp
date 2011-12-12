# encoding: UTF-8
#--
#
# Copyright 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2009, 2010, 2011, 2012 Marius L. Jøhndal
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

module Ordering
  # Returns true if there is a previous object in the collection.
  def has_previous?
    ordering_collection.exists?(["#{ordering_attribute} < ?", self.send(ordering_attribute)])
  end

  # Returns true if there is a next object in the collection.
  def has_next?
    ordering_collection.exists?(["#{ordering_attribute} > ?", self.send(ordering_attribute)])
  end
end
