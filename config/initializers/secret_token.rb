Proiel::Application.configure do
  if ENV['PROIEL_SECRET_TOKEN']
    config.secret_token = ENV['PROIEL_SECRET_TOKEN']
  elsif Rails.env.development? or Rails.env.test?
    puts 'Warning: Generating random secret token'.yellow
    Rails.logger.warn 'Generating random secret token'
    config.secret_token = SecureRandom.hex(64)
  end
end
