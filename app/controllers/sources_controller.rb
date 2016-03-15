#--
#
# Copyright 2007-2012 University of Oslo
# Copyright 2007-2016 Marius L. Jøhndal
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

class SourcesController < ApplicationController
  respond_to :html, :xml
  before_filter :is_administrator?, :only => [:edit, :update]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def index
    @sources = Source.order(:language_tag).page(current_page).per(90)

    respond_with @sources
  end

  def show
    @source = Source.includes(:source_divisions).find(params[:id])
    @source_divisions = @source.source_divisions.order(:position).page(current_page).per(300)

    sentences = @source.sentences
    @activity_stats = sentences.annotated.group("DATE_FORMAT(annotated_at, '%Y-%m-%d')").order('annotated_at DESC').limit(10).count
    @sentence_completion_stats = @source.aggregated_status_statistics
    @annotated_by_stats = sentences.annotated.group(:annotator).count.map { |k, v| [k.try(:full_name), v] }
    @reviewed_by_stats = sentences.reviewed.group(:reviewer).count.map { |k, v| [k.try(:full_name), v] }

    respond_with @source
  end

  def edit
    @source = Source.find(params[:id])

    respond_with @source
  end

  def update
    normalize_unicode_params! params[:source], :author

    @source = Source.find(params[:id])
    @source.update_attributes(params[:source])

    respond_with @source
  end
end
