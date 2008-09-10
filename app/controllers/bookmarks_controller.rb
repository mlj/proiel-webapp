class BookmarksController < ResourceController::Base
  before_filter :is_reviewer?
  before_filter :find_parents

  protected

  def find_parents
    @parent = @user = User.find(params[:user_id]) unless params[:user_id].blank?
  end

  private

  def collection
    @bookmarks = (@parent ? @parent.bookmarks : Bookmark).search(params[:query], :page => current_page)
  end
end
