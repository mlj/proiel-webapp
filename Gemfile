source "https://rubygems.org"
ruby "2.0.0"

gem 'rails'
gem 'json'

gem 'sass-rails'
#group :assets do
#  gem 'coffee-rails', '~> 3.2.1'
#  gem 'therubyracer'
#  gem 'uglifier', '>= 1.0.3'
#end

gem 'formtastic'
gem 'kaminari'
gem 'haml'
gem 'devise'
gem 'devise-encryptable'
gem 'high_voltage'
gem 'exception_notification'
gem 'audited-activerecord', '~> 3.0'
gem 'ransack'

gem 'unicode'

gem 'builder' # builder is faster than Nokogiri's built-in builder
gem 'nokogiri'
gem 'nori'

gem 'gchartrb', :require => 'google_chart'
gem 'diff-lcs', :require => 'diff/lcs'
gem 'alignment'
gem 'redcarpet'
gem 'differ'
gem 'iso-codes', :require => 'iso_codes'
gem 'ruby-sfst', :require => 'sfst'
gem 'colorize'

group :production, :development do
  gem 'mysql2', '> 0.3.0'
  gem 'pg'
  gem 'thin'
end

group :test do
  gem "sqlite3"
end

gem 'foreman'
gem 'dotenv'
gem 'coveralls', require: false, group: :test

group :development, :test do
  gem 'rspec-rails', '~> 2.0'
  gem 'factory_girl_rails'
  gem 'faker'
end
