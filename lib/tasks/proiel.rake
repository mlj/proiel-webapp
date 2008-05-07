#TODO
USER_NAME='mlj'

DEFAULT_EXPORT_DIRECTORY = File.join(RAILS_ROOT, 'public', 'exports')

namespace :proiel do
  task(:myenvironment => :environment) do
    require 'jobs'
  end

  desc "Validate PROIEL database"
  task(:validator => :myenvironment) do
    require 'tools/db_validator'

    v = Validator.new(false)
    v.execute!(USER_NAME)
  end

  desc "Import a PROIEL source text. Options: FILE=data_file BOOK=book_filter" 
  task(:import => :environment) do
    require 'tools/proiel_import'
    args = []
    if ENV['BOOK']
      args << '--book'
      args << ENV['BOOK']
    end
    args << ENV['FILE']
    i = PROIELImport.new(ENV['FILE'], ENV['BOOK'])
    i.execute!(USER_NAME)
  end

  desc "Export a PROIEL source text. Options: ID=source_identifier"
  task(:export => :environment) do
    s = Source.find_by_code(ENV['ID'])
    raise "Source not found" unless s
    s.export("#{s.code}.xml")
  end

  namespace :export do
    namespace :all do
      desc "Export all PROIEL source texts with all publicly available data."
      task(:public => :myenvironment) do
        Dir::mkdir(DEFAULT_EXPORT_DIRECTORY) unless File::directory?(DEFAULT_EXPORT_DIRECTORY)
        File::copy(File.join(RAILS_ROOT, 'data', 'text.xsd'), 
                   File.join(DEFAULT_EXPORT_DIRECTORY, 'text.xsd'))
        File::copy(File.join(RAILS_ROOT, 'lib', 'proiel', 'morphology.xml'), 
                   File.join(DEFAULT_EXPORT_DIRECTORY, 'morphology.xml'))
        File::copy(File.join(RAILS_ROOT, 'lib', 'proiel', 'relations.xml'), 
                   File.join(DEFAULT_EXPORT_DIRECTORY, 'relations.xml'))
        Source.find(:all).each do |source|
          source.export(File.join(DEFAULT_EXPORT_DIRECTORY, "#{source.code}.xml"), :reviewed_only => true)
        end
      end
    end
  end
end
