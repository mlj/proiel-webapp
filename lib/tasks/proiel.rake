require 'fileutils'

desc "Periodically run the cache updater job"
task :run_cache_updater => :environment do
  job = Proiel::Jobs::CacheUpdater.new
  job.run_periodically!(1.hour)
end
