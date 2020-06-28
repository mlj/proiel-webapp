source 'https://rubygems.org'

gem 'rails', '3.2.22.2'
gem 'json'
gem 'sass-rails'
gem 'proiel'
gem 'rack-utf8_sanitizer'

gem 'formtastic'
gem 'kaminari'
gem 'haml', '~> 4.0.4'
gem 'devise', '~> 2.2.4'
gem 'devise-encryptable'
gem 'audited-activerecord', '~> 3.0'
gem 'ransack', '~> 0.7.2'

gem 'unicode'

gem 'builder' # builder is faster than Nokogiri's built-in builder
gem 'nokogiri'
gem 'nori'

gem 'diff-lcs', :require => 'diff/lcs'
gem 'alignment'
gem 'differ'
gem 'iso-codes', :require => 'iso_codes'
gem 'ruby-sfst', :require => 'sfst'
gem 'colorize'

group :production, :development do
  if ENV['HOSTNAME'] == 'hf-tekstlab-ny02.uio.no'
    # Stay on 0.4 to keep support for MySQL < 5.5
    gem 'mysql2', '~> 0.4.0'
  else
    # Rails 3.2.22.x has it's own crazy requirement for a 0.3 version (see
    # activerecord-3.2.22.2/lib/active_record/connection_adapters/mysql2_adapter.rb)
    gem 'mysql2', '~> 0.3.0'
  end
end

gem 'foreman'
gem 'dotenv'
gem 'unicorn'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'sqlite3'
  gem 'test-unit'
end
