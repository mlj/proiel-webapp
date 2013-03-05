class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!

  helper :all

  layout 'application'

  def user_is_reviewer?
    current_user.has_role?(:reviewer)
  end

  helper_method :user_preferences

  # Returns the user's preference settings.
  def user_preferences
    current_user.try(:preferences) || { :graph_format => "png", :graph_method => "unsorted" }
  end

  helper_method :current_page

  # Returns the current page for pagination.
  def current_page
    @page ||= params[:page].blank? ? 1 : params[:page].to_i
  end

  def check_role(role)
    unless user_signed_in? && current_user.has_role?(role)
      if user_signed_in?
        flash[:error] = 'You do not have permission to access this feature.'
        redirect_to "/"
      else
        access_denied
      end
    end
  end

  def is_administrator?
    check_role(:administrator)
  end

  def is_reviewer?
    check_role(:reviewer)
  end

  def is_annotator?
    check_role(:annotator)
  end

  def is_reader?
    check_role(:reader)
  end

  def record_not_found
    flash[:error] = 'No such object'
    redirect_to :root
  end
end
