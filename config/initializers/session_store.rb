# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_proiel_session',
  :secret      => '32142b796868de53a2def939cca7017812d8e1b9e90c502b82e8c6b0553b1e1fbc8311eef980dc1f29edfb9cb448815961a85e13045db32669ec8a45705009d3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
