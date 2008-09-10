class NotesController < ResourceController::Base
  # Only reviewers may edit or delete notes
  before_filter :is_reviewer?, :only => [ :update, :destroy ]

  private

  def collection
    @notes = Note.search(params[:query], :page => current_page)
  end
end
