class JobsController < ResourceController::Base # ApplicationController
  before_filter :is_annotator?
  actions :all, :except => [ :new, :edit, :create, :update, :destroy ]

  private

  def collection
    @jobs = Job.search(params.slice(:user), params[:page])
  end
end
