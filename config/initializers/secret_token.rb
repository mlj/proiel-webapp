# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

if ENV['PROIEL_SECRET_TOKEN']
  Proiel::Application.config.secret_token = ENV['PROIEL_SECRET_TOKEN']
elsif Rails.env.development? or Rails.env.test?
  puts 'Warning: Generating random secret token'.yellow
  Rails.logger.warn 'Generating random secret token'
  Proiel::Application.config.secret_token = SecureRandom.hex(64)
end
