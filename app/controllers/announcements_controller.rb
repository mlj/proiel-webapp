class AnnouncementsController < ResourceController::Base
  before_filter :is_administrator?

  private

  def collection
    @announcements = Announcement.search(params[:query], :page => current_page)
  end
end
