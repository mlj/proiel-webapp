#--
#
# Copyright 2014 Marius L. Jøhndal
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

class TagsController < ApplicationController
  respond_to :html
  before_filter :is_reviewer?

  def index
    if params[:tag] and params[:value]
      @semantic_tags = SemanticTag.
        includes(semantic_attribute_value: [:semantic_attribute]).
        order('semantic_attributes.tag, semantic_attribute_values.tag').
        where('semantic_attributes.tag' => params[:tag]).
        where('semantic_attribute_values.tag' => params[:value]).
        page(current_page)

      respond_with @semantic_tags
    elsif params[:tag]
      @semantic_attribute_values = SemanticAttributeValue.
        includes(:semantic_attribute).
        order('semantic_attribute_values.tag').
        where('semantic_attributes.tag' => params[:tag]).
        page(current_page)

      respond_with @semantic_attribute_values
    else
      @semantic_attributes = SemanticAttribute.
        order('semantic_attributes.tag').
        page(current_page)

      respond_with @semantic_attributes
    end
  end
end
