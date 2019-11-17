require 'active_record/fixtures'

Dir.glob(Rails.root.join('db', 'fixtures', '*.yml')).each do |file|
  ActiveRecord::Fixtures.create_fixtures('db/fixtures', File.basename(file, '.*'))
end
