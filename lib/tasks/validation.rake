namespace :db do
  desc "Run model validations on all model records in database"
  task :validate => :environment do
    puts "-- records - model --"
    Dir.glob(RAILS_ROOT + '/app/models/**/*.rb').each { |file| require file unless file =~ /observer/ }
    Object.subclasses_of(ActiveRecord::Base).select { |c| c.base_class == c}.sort_by(&:name).each do |klass|
      next if klass == CGI::Session::ActiveRecordStore::Session
      total = klass.count
      printf "%10d - %s\n", total, klass.name
      chunk_size = 500
      (total / chunk_size + 1).times do |i|
        chunk = klass.find(:all, :offset => (i * chunk_size), :limit => chunk_size)
        chunk.reject(&:valid?).each do |record|
          puts "#{record.class}: id=#{record.id}"
          p record.errors.full_messages
          puts
        end rescue nil
      end
    end
  end
end
