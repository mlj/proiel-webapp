class ChangesetsController < ReadOnlyController
  before_filter :is_annotator?
  before_filter :find_parents

  protected

  def find_parents
    @parent = @user = User.find(params[:user_id]) unless params[:user_id].blank?
  end

  private

  def collection
    @changesets = (@parent ? @parent.changesets : Changeset).search(params[:query], :page => current_page)
  end
end
