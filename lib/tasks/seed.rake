namespace :db do
  desc "Create seed fixtures from data in the current environment's database."
  task :extract_seed_fixtures => :environment do
    sql  = "SELECT * FROM %s"
    ActiveRecord::Base.establish_connection
    %W{languages parts_of_speech morphologies relations relation_equivalences roles}.each do |table_name|
      i = "000"
      File.open(RAILS_ROOT + "/db/fixtures/#{table_name}.yml", 'w') do |file|
        data = ActiveRecord::Base.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end

  desc "Create test fixtures from data in the current environment's database."
  task :extract_test_fixtures => :environment do
    sql = "SELECT * FROM %s"
    skip_tables = ["schema_info", "sessions"]
    ActiveRecord::Base.establish_connection
    tables = ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : ActiveRecord::Base.connection.tables - skip_tables
    tables.each do |table_name|
      i = "000"
      File.open(RAILS_ROOT + "/test/fixtures/#{table_name}.yml", 'w') do |file|
        data = ActiveRecord::Base.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end
end
