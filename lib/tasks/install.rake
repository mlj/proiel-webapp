desc 'Generate a template .env file'
task :generate_env do
  env_file = Rails.root.join('.env')

  if File.exists?(env_file)
    puts ".env file already exists".red
  else
    File.open(env_file, 'w') do |f|
      f.puts "# A secret session token for the application"
      f.puts "PROIEL_SECRET_TOKEN=#{SecureRandom.hex(64)}"
      f.puts "# Site base URL"
      f.puts "#PROIEL_BASE_URL=http://somewhere"
      f.puts "# The e-mail address used as the sender of registration e-mails"
      f.puts "#PROIEL_REGISTRATION_MAILER_SENDER_ADDRESS="
    end
  end
end
