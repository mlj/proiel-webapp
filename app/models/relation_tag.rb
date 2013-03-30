#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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

class RelationTag < TagObject
  model_file_name 'relation.yml'

  PREDICATIVE_RELATIONS = %w(xobj xadv)
  APPOSITIVE_RELATIONS = %w(apos)
  # FIXME: a misnomer
  NOMINAL_RELATIONS = %w(part obl sub obj narg voc)

  # Returns true if the relation is a predicative relation.
  def predicative?
    PREDICATIVE_RELATIONS.include?(tag)
  end

  # Returns true if the relation is a appositive relation.
  def appositive?
    APPOSITIVE_RELATIONS.include?(tag)
  end

  # Returns true if the relation is a nominal relation.
  def nominal?
    # FIXME: a misnomer
    NOMINAL_RELATIONS.include?(tag)
  end

  def to_s
    tag
  end

  def to_label
    tag
  end
end
