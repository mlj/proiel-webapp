# Settings specified here will take precedence over those in config/environment.rb
config.active_record.observers = :user_observer

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = true

# We care if the mailer can't send
config.action_mailer.raise_delivery_errors = true 
config.action_mailer.delivery_method = :sendmail

SITE_CANONICAL_URL = 'http://foni.uio.no:3001'
SITE_ADMINISTRATOR_EMAIL = 'mariuslj@ifi.uio.no'
