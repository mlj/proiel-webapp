source 'https://rubygems.org'

gem 'activerecord'
gem 'builder'
gem 'colorize'
gem 'nokogiri'
gem 'nori'
gem 'proiel'
gem 'unicode'
gem 'tzinfo'

group :production, :development do
  # Stay on 0.4 to keep support for MySQL < 5.5
  gem 'mysql2', '~> 0.4.0'
end

group :test do
  gem 'factory_girl'
  gem 'rspec'
  gem 'simplecov', require: false
  gem 'sqlite3'
  gem 'test-unit'
end
