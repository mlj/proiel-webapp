#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Marius L. Jøhndal
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

class DependencyAlignmentTerm < ActiveRecord::Base
  attr_accessible :token_id, :source_id
  change_logging

  belongs_to :token
  belongs_to :source
end
