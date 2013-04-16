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

class NotesController < ApplicationController
  respond_to :html
  before_filter :is_reviewer?, :only => [:edit, :update, :destroy]

  def show
    @note = Note.find(params[:id])

    respond_with @note
  end

  def edit
    @note = Note.find(params[:id])

    respond_with @note
  end

  def update
    @note = Note.find(params[:id])

    flash[:notice] = 'Note updated' if @note.update_attributes(params[:note])

    respond_with @note
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages

    respond_with @note
  end

  def destroy
    @note = Note.find(params[:id])
    notable = @note.notable

    @note.destroy
    flash[:notice] = 'Note deleted'

    redirect_to notable
  end
end
