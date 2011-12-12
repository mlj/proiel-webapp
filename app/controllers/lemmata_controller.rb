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

class LemmataController < ApplicationController
  respond_to :html
  before_filter :is_reviewer?, :only => [:edit, :update, :merge]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @lemma = Lemma.find(params[:id])

    if @lemma.nil?
      raise ActiveRecord::RecordNotFound
    else
      @semantic_tags = @lemma.semantic_tags
      @tokens = @lemma.tokens.page(current_page)
      @mergeable_lemmata = @lemma.mergeable_lemmata

      respond_with @lemma
    end
  end

  def edit
    @lemma = Lemma.find(params[:id])

    respond_with @lemma
  end

  def update
    normalize_unicode_params! params[:lemma], :lemma

    @lemma = Lemma.find(params[:id])
    @lemma.update_attributes(params[:lemma])

    respond_with @lemma
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages

    respond_with @lemma
  end

  def merge
    @lemma = Lemma.find(params[:id])
    @other_lemma = Lemma.find(params[:other_id])

    if @lemma.mergeable?(@other_lemma)
      @lemma.merge!(@other_lemma)

      flash[:notice] = "Lemmata sucessfully merged"
    else
      flash[:error] = "Lemmata cannot be merged because base form, language or part of speech do not match"
    end

    respond_with @lemma
  end
end
