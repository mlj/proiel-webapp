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

RAILS_GEM_VERSION = '2.3.11' unless defined? RAILS_GEM_VERSION

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
  config.plugins = [ :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  config.gem 'warden', :version => '~> 0.9'
  config.gem 'devise', :version => '~> 1.0.0'
  config.gem 'will_paginate', :version => '~> 2.3.2'
  config.gem 'unicode'
  config.gem 'oniguruma'
  config.gem 'builder'
  config.gem 'nokogiri'
  config.gem 'hpricot', :version => '0.8.1' # only needed for legacy_import
  config.gem 'gchartrb', :lib => 'google_chart'
  config.gem 'diff-lcs', :lib => 'diff/lcs'
  config.gem 'ruby-sfst', :lib => 'sfst'
  config.gem 'mlj-alignment', :lib => 'alignment', :source => 'http://gems.github.com'
  # We need 0.9.3 < version < 1.0  to satisfy libxslt-ruby, which
  # unfortunately has not been updated in a while.
  config.gem 'libxml-ruby', :lib => 'libxml', :version => '0.9.9'
  config.gem 'libxslt-ruby', :lib => 'libxslt'
  config.gem 'log4r'
  config.gem 'mlj-unicode_normalization_validation', :lib => 'unicode_normalization_validation', :source => 'http://gems.github.com'
  config.gem 'bluecloth'
  config.gem 'formtastic'
  config.gem 'inherited_resources', :version => '~> 1.0.3'
  config.gem 'haml'
  config.gem 'acts_as_audited', :lib => false
  config.gem 'exception_notification'
  config.gem 'iso-codes', :lib => 'iso_codes'
  config.gem 'differ'
end

# Release number
PROIEL_RELEASE_FILE = File.join(RAILS_ROOT, "RELEASE")
PROIEL_RELEASE = File.readable?(PROIEL_RELEASE_FILE) ? IO.read(PROIEL_RELEASE_FILE).strip : "unreleased"
