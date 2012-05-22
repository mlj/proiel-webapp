#--
#
# Copyright 2012 University of Oslo
# Copyright 2012 Marius L. Jøhndal
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

class DictionariesController < ApplicationController
  respond_to :html, :xml

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def index
    @dictionaries = Lemma.group(:language_tag).map(&:language)

    respond_with @dictionaries
  end

  def show
    @dictionary = Language.new(params[:id])
    @search = Lemma.where(:language_tag => params[:id]).order(:lemma).search(params[:search])
    @lemmata = @search.page(current_page)

    respond_with @dictionary
  end
end
