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

class SearchesController < ApplicationController
  respond_to :html

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @search = Token.search(params[:search])
    @tokens = @search.page(current_page)

    respond_with @search
  end

  # Returns suggestions for Open Search suggestion queries.
  def quick_search_suggestions
    query = params[:query] || ""
    query.strip!

    if query.empty?
      @results = []
    else
      @results = Token.find(:all, :conditions => ["form LIKE ?", "#{query}%"], :limit => 10).map(&:form)
    end

    @results.uniq!
    @results.sort!

    respond_to do |format|
      format.js { render :json => [query, @results].to_json }
    end
  end

  def quick_search
    query = params[:query] || ""
    query.strip!

    case query
    when /^\d+$/
      redirect_to sentence_url(query.to_i)
    else
      redirect_to create_searches_url #Search.new #({ :action => :create }, :search => { :token_form => query })
    end
  end
end
