# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
require 'active_record/fixtures'

Dir.glob(Rails.root.join('db', 'fixtures', '*.yml')).each do |file|
  ActiveRecord::Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
end
