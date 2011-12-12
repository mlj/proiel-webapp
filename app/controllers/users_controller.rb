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

class UsersController < ApplicationController
  respond_to :html
  before_filter :is_administrator?

  def index
    @users = User.order('login').page(current_page)

    respond_with @users
  end

  def show
    @user = User.find(params[:id])

    respond_with @user
  end
end
