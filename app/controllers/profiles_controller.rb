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

class ProfilesController < ApplicationController
  respond_to :html

  def edit
    @user = current_user

    respond_with @user
  end

  def update
    if params[:user]
      @user = current_user
      @user.preferences_will_change!
      @user.update_attributes! :graph_format => params[:user][:graph_format],
        :graph_method => params[:user][:graph_method]

      redirect_to :root
    else
      redirect_to :edit
    end
  end
end
