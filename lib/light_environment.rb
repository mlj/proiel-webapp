#
# 
#
# $Id: $
#
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'vendor', 'plugins')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'vendor', 'plugins', 'enum-column', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'vendor', 'plugins', 'acts_as_versioned', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'vendor', 'rails', 'activerecord', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'vendor', 'rails', 'actionpack', 'lib')

require 'active_record'
require 'acts_as_versioned'
require 'enum/active_record_helper'
require 'app/models/book'
require 'app/models/lemma'
require 'app/models/source'
require 'app/models/token'
require 'app/models/sentence'

def open_environment(config = 'config/database.yml', environment = nil)
  environment ||= ENV['RAILS_ENV']
  environment ||= 'development'
  dbconfig = YAML::load(File.open(config))
  raise "Unable to read environment configuration" unless dbconfig
  ActiveRecord::Base.establish_connection(dbconfig[environment].merge!({ 'encoding' => 'utf8'}))
  yield
end
