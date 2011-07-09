# Controller for static pages.
#
# Idea taken from http://giantrobots.thoughtbot.com/2008/4/2/static-pages-for-the-enterprise.
class PageController < ApplicationController
  PAGES = %w(help public_data searching short_cuts fonts attributions known_issues change_log maintenance)

  verify :params => :name, :only => :show, :redirect_to => :root_url
  before_filter :ensure_valid, :only => :show

  def show
    render :template => "pages/#{current_page}"
  end

  protected

  def current_page
    params[:name].to_s.downcase
  end

  def ensure_valid
    unless PAGES.include? current_page
      render :nothing => true, :status => 404 and return false
    end
  end
end
