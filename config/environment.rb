# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

$KCODE = 'u'

# Unicode normalization form for normalised text columns. Choices are :kc, :c, :kd, :d
# (see http://unicode.org/reports/tr15/ for details). The default choice is :c, and it is
# recommended that you stick with that unless you have good reasons not to. If you do change
# it, remeber to take into consideration how your database engine deals with queries that
# contain sequences of potentially decomposed characters.
UNICODE_NORMALIZATION_FORM = :c

# Default user preferences.
DEFAULT_USER_PREFERENCES = { :graph_format => "png", :graph_method => "unsorted" }

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.1' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  config.frameworks -= [ :active_resource ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  config.plugins = [ :userstamp, :all ] 

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_proiel_session',
    :secret      => '32142b796868de53a2def939cca7017812d8e1b9e90c502b82e8c6b0553b1e1fbc8311eef980dc1f29edfb9cb448815961a85e13045db32669ec8a45705009d3'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  config.gem 'mislav-will_paginate', :version => '~> 2.3.2', :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem 'unicode'
  config.gem 'oniguruma'
  config.gem 'builder'
  config.gem 'hpricot'
  config.gem 'gchartrb', :lib => 'google_chart'
  config.gem 'treetop'
  config.gem 'diff-lcs', :lib => 'diff/lcs'
  config.gem 'ruby-sfst', :lib => 'sfst'
  config.gem 'logos'
end
