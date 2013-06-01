# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

secret_token_file = Rails.root.join('config', 'secret_token')

if File.exists?(secret_token_file)
  Proiel::Application.config.secret_token = File.open(secret_token_file).read
else
  puts "Missing secret token file #{secret_token_file}"
  puts
  puts "*********************************************************************".red
  puts "Read step 6 of the installation guide (doc/guide.mkd) if this message".red
  puts "doesn't make sense to you!".red
  puts "*********************************************************************".red
  exit
end
