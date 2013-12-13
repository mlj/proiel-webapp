# Load the rails application
require File.expand_path('../application', __FILE__)

# Settings specific to the PROIEL application (i.e. not Rails). You can
# override these settings in config/environments/*.
Proiel::Application.configure do
  # If true, will log changes to annotation objects in the changelog.
  config.auditing = true

  # The location for schema files used for validating exports.
  config.schema_file_path = Rails.root.join('public', 'exports')

  # The location for exported files.
  config.export_directory_path = Rails.root.join('public', 'exports')

  # The location for tagset files.
  config.tagset_file_path = Rails.root.join('config', 'tagsets')

  # Pull in configuration variables from the .env file
  Dotenv.load

  # Configure action mailer
  config.action_mailer.delivery_method = if Rails.env.test?
      :test
    else
      :sendmail
    end

  config.action_mailer.default_url_options = {
    host: ENV['PROIEL_BASE_URL']
  }

  config.action_mailer.sendmail_settings = {
    location:  '/usr/sbin/sendmail',
    arguments: '-i'
  }
end

# Initialize the rails application
Proiel::Application.initialize!
