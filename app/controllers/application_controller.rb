class ApplicationController < ActionController::Base
  before_filter :authenticate_user!

  include Userstamp

  helper :all
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  filter_parameter_logging :password, :password_confirmation

  layout 'proiel' 

  def user_is_reviewer?
    current_user.has_role?(:reviewer)
  end

  helper_method :user_preferences

  # Returns the current user's preference settings.
  def user_preferences
    current_user.preferences || DEFAULT_USER_PREFERENCES
  end

  helper_method :current_page

  # Returns the current page for will_paginate based actions.
  def current_page
    @page ||= params[:page].blank? ? 1 : params[:page].to_i
  end

  def check_role(role)
    unless user_signed_in? && @current_user.has_role?(role)
      if user_signed_in?
        flash[:error] = 'You do not have permission to access this feature.'
        redirect_back_or_default('/')
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
end
