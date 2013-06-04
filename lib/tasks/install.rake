desc 'Generate a template .env file'
task :generate_env do
  env_file = Rails.root.join('.env')

  if File.exists?(env_file)
    puts ".env file already exists".red
  else
    File.open(env_file, 'w') do |f|
      f.puts "# A secret session token for the application"
      f.puts "PROIEL_SECRET_TOKEN=#{SecureRandom.hex(64)}"
      f.puts "# A space-separated list of e-mail addresses that receive exception notifications"
      f.puts "PROIEL_EXCEPTION_NOTIFICATION_RECIPIENT_ADDRESSES="
      f.puts "# An e-mail used as the sender of exception notificationss"
      f.puts "PROIEL_EXCEPTION_NOTIFICATION_SENDER_ADDRESS="
    end
  end
end
