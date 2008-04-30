class ApplicationController < ActionController::Base
  helper :all

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '7becd11968ff1efe5b37bfc0a780d63d'
  
  include AuthenticatedSystem
  before_filter :login_required

  include ExceptionNotifiable

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_proiel_session_id'

  layout 'proiel' 
end
