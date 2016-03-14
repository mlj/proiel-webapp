require 'fileutils'

desc "Periodically run the cache updater job"
task :run_cache_updater => :environment do
  job = Proiel::Jobs::CacheUpdater.new
  job.run_periodically!(1.hour)
end

desc "Periodically run the checker job"
task :run_checker_job => :environment do
  database_checker = Proiel::Jobs::DatabaseChecker.new
  database_checker.run_periodically!(1.hour)
end

namespace :proiel do
  desc "Validate database objects"
  task(:validate => :environment) do
    database_validator = Proiel::Jobs::DatabaseValidator.new
    database_validator.run_once!
  end
end
