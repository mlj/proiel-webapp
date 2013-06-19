unless ENV['PROIEL_EXCEPTION_NOTIFICATION_RECIPIENT_ADDRESSES'].blank?
  Rails.logger.info 'Enabling exception notification'

  Rails.application.config.middleware.use ExceptionNotifier,
    email_prefix: "PROIEL: ",
    sender_address: ENV['PROIEL_EXCEPTION_NOTIFICATION_SENDER_ADDRESS'] || %{"PROIEL exception notifier" <notifier@example.com>},
    exception_recipients: ENV['PROIEL_EXCEPTION_NOTIFICATION_RECIPIENT_ADDRESSES'].split
end
