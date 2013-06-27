Proiel::Application.configure do
  if Rails.env.test?
    config.action_mailer.delivery_method = :test
  else
    config.action_mailer.delivery_method = :sendmail
  end

  config.action_mailer.default_url_options = { :host => ENV['PROIEL_BASE_URL'] }
  config.action_mailer.sendmail_settings = {
    :location       => '/usr/sbin/sendmail',
    :arguments      => '-i'
  }
end
