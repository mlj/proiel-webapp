# Derived from http://blog.craigambrose.com/articles/2007/03/01/a-rake-task-for-database-backups
require 'find'
require 'ftools'

namespace :db do  
  desc "Backup the database to a file. Options: DIR=backup_folder RAILS_ENV=production MAX=20" 

  task :backup => [:environment] do
    # Grab arguments
    max_backups = ENV["MAX"] || 20 
    max_backups = max_backups.to_i
    backup_folder = ENV["DIR"] || File.join('db', 'backup')

    # Figure out directories and file names
    datestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    backup_file = File.join(backup_folder, "#{RAILS_ENV}-#{datestamp}.sql.gz")
    File.makedirs(backup_folder)

    # Do the dump
    db_config = ActiveRecord::Base.configurations[RAILS_ENV]
    sh "mysqldump -u#{db_config['username']} -p#{db_config['password']} --add-drop-table --add-locks #{db_config['database']} | gzip -c > #{backup_file}"
    puts "Created backup #{backup_file}"

    # Clean up old mess
    dir = Dir.new(backup_folder)
    all_backups = dir.select { |e| e[/\.sql\.gz$/] }.entries[2..-1].sort.reverse
    unwanted_backups = all_backups[max_backups..-1] || []
    for unwanted_backup in unwanted_backups
      File.unlink(File.join(backup_folder, unwanted_backup))
      puts "Deleted #{unwanted_backup}" 
    end
  end
end
