source 'https://rubygems.org'

gem 'rails', '3.2.22.2'
gem 'json'
gem 'sass-rails'

gem 'proiel', '1.1.1'

gem 'formtastic'
gem 'kaminari'
gem 'haml'
gem 'devise', '~> 2.2.4'
gem 'devise-encryptable'
gem 'exception_notification', '~> 3.0.1'
gem 'audited-activerecord', '~> 3.0'
gem 'ransack', '~> 0.7.2'

gem 'unicode'

gem 'builder' # builder is faster than Nokogiri's built-in builder
gem 'nokogiri'
gem 'nori'

gem 'gchartrb', :require => 'google_chart'
gem 'diff-lcs', :require => 'diff/lcs'
gem 'alignment'
gem 'differ'
gem 'iso-codes', :require => 'iso_codes'
gem 'ruby-sfst', :require => 'sfst'
gem 'colorize'

# Stay below rack-cache 1.10.0 while we have to support Ruby 2.2
# https://github.com/rtomayko/rack-cache/commit/ec14406240c177df05ea641cbb790cc182d48b25
gem 'rack-cache', '< 1.10.0'

group :production, :development do
  # Stay on 0.4 to keep support for MySQL < 5.5
  #gem 'mysql2', '~> 0.4.0'
  # Rails 3.2.22.x has it's own crazy requirement for a 0.3 version (see
  # activerecord-3.2.22.2/lib/active_record/connection_adapters/mysql2_adapter.rb)
  gem 'mysql2', '~> 0.3.0'
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
