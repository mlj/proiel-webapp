#--
#
# Copyright 2010, 2011, 2012 University of Oslo
# Copyright 2010, 2011, 2012 Dag Haug
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

class SemanticRelation < ActiveRecord::Base
  attr_accessible :target_id, :controller_id, :sematic_relation_tag_id
  change_logging

  belongs_to :controller, :class_name => 'Token', :foreign_key => 'controller_id'
  belongs_to :target, :class_name => 'Token', :foreign_key => 'target_id'
  belongs_to :semantic_relation_tag

  validates_presence_of :semantic_relation_tag
  validates_presence_of :controller
  validates_presence_of :target

  validate do
    errors[:base] << "Controller and target must be in the same source division" unless controller.sentence.source_division == target.sentence.source_division
  end

  delegate :semantic_relation_type, :to => :semantic_relation_tag
end
