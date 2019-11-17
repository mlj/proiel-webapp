source 'https://rubygems.org'

gem 'activerecord'
gem 'builder' # builder is faster than Nokogiri's built-in builder
gem 'colorize'
gem 'nokogiri'
gem 'nori'
gem 'proiel', '~> 1.3.0'
gem 'unicode'
gem 'tzinfo'

group :production, :development do
  gem 'mysql2'
end

group :test do
  gem 'factory_girl'
  gem 'rspec'
  gem 'simplecov', require: false
  gem 'sqlite3'
  gem 'test-unit'
end
