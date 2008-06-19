class ChangesetsController < ResourceController::Base # ApplicationController
  before_filter :is_annotator?
  actions :all, :except => [ :new, :edit, :create, :update, :destroy ]

  private

  def collection
    @changesets = Changeset.search(params.slice(:user), params[:page])
  end
end
