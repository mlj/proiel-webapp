# Load the rails application
require File.expand_path('../application', __FILE__)

# Settings specific to the PROIEL application (i.e. not Rails). You can
# override any of these settings in config/environments/*.
Proiel::Application.configure do
  # If true, will log changes to annotation objects in the changelog.
  config.auditing = true
end

# Initialize the rails application
Proiel::Application.initialize!
