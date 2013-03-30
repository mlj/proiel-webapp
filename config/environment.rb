# Load the rails application
require File.expand_path('../application', __FILE__)

# Settings specific to the PROIEL application (i.e. not Rails). You can
# override any of these settings in config/environments/*.
Proiel::Application.configure do
  # If true, will log changes to annotation objects in the changelog.
  config.auditing = true

  # The location for schema files used for validating exports.
  config.schema_file_path = Rails.root.join('public', 'exports')

  # The location for exported files.
  config.export_directory_path = Rails.root.join('public', 'exports')

  # The location for tagset files.
  config.tagset_file_path = Rails.root.join('config', 'tagsets')
end

# Initialize the rails application
Proiel::Application.initialize!
