IGNORED_MODELS = %w(Audit Inflection)

namespace :db do
  desc "Run model validations on model records in database"
  task :validate => :environment do
    puts "-- records - model --"
    Dir.glob(Rails.root.join('app', 'models', '**', '*.rb')).each { |file| require file unless file =~ /mailer|observer/ }
    Object.subclasses_of(ActiveRecord::Base).select { |c| c.base_class == c}.sort_by(&:name).each do |klass|
      next if klass.to_s[/Store::Session$/]
      next if IGNORED_MODELS.include?(klass.to_s) # ignore a few non-critical models to save time

      total = klass.count
      chunk_size = 500
      (total / chunk_size + 1).times do |i|
        chunk = klass.find(:all, :offset => (i * chunk_size), :limit => chunk_size)
        chunk.reject(&:valid?).each do |record|
          if record.class == Sentence
            puts "#{record.class}: id=#{record.id} (#{record.is_reviewed? ? 'Reviewed' : 'Not reviewed'})"
          else
            puts "#{record.class}: id=#{record.id}"
          end

          p record.errors.full_messages
          puts
        end rescue nil
      end
    end
  end
end
