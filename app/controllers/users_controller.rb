class UsersController < InheritedResources::Base
  actions :index, :show

  before_filter :is_administrator?

  private

  def collection
    @users = User.search(params[:query], :page => current_page)
  end
end
