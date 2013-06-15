Dotenv.load

Proiel::Application.configure do
  if ENV['PROIEL_SECRET_TOKEN']
    config.secret_token = ENV['PROIEL_SECRET_TOKEN']
  elsif Rails.env.development? or Rails.env.test?
    puts 'Warning: Generating random secret token'.yellow
    Rails.logger.warn 'Generating random secret token'
    config.secret_token = SecureRandom.hex(64)
  end
end

# Exception notification
unless ENV['PROIEL_EXCEPTION_NOTIFICATION_RECIPIENT_ADDRESSES'].blank?
  Rails.logger.info 'Enabling exception notification'

  Rails.application.config.middleware.use ExceptionNotifier,
    email_prefix: "PROIEL: ",
    sender_address: ENV['PROIEL_EXCEPTION_NOTIFICATION_SENDER_ADDRESS'] || %{"PROIEL exception notifier" <notifier@example.com>},
    exception_recipients: ENV['PROIEL_EXCEPTION_NOTIFICATION_RECIPIENT_ADDRESSES'].split
end
