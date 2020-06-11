#--
#
# Copyright 2007-2012 University of Oslo
# Copyright 2007-2017 Marius L. Jøhndal
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

class SourceDivisionsController < ApplicationController
  respond_to :html, :xml
  before_action :is_administrator?, :only => [:edit, :update]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @source_division = SourceDivision.includes(:source).find(params[:id])
    @source = @source_division.source
    @sentences = @source_division.sentences.order(:sentence_number).page(current_page).per(90)

    respond_with @source_division
  end

  def edit
    @source_division = SourceDivision.includes(:source).find(params[:id])
    @source = @source_division.source

    respond_with @source_division
  end

  def update
    normalize_unicode_params! params[:source_division], :presentation_before, :presentation_after

    @source_division = SourceDivision.find(params[:id])
    @source_division.update!(source_division_params)

    respond_with @source_division
  end

  private

  def source_division_params
    params.require(:source_division).permit(:source_id, :position, :title,
                                            :aligned_source_division_id, :presentation_before, :presentation_after,
                                            :created_at, :updated_at)
  end
end
