class UsersController < ApplicationController
  before_filter :is_administrator?

  def index
    @users = User.search(params[:query], :page => current_page)
  end

  def show
   @user = User.find(params[:id])
  end
end
