
#TODO
USER_NAME='mlj'

namespace :proiel do
  task(:myenvironment => :environment) do
    # FIXME: bootstrap legacy tool system
    require 'tools'
  end

  desc "Validate PROIEL database"
  task(:validator => :myenvironment) do
    PROIEL::Tools.execute('db-validator', USER_NAME)
  end

  namespace :import do
    desc "Import a PROIEL source text. Options: FILE=data_file BOOK=book_filter" 

    task(:proiel => :environment) do
      require 'tools'

      args = []
      if ENV['BOOK']
        args << '--book'
        args << ENV['BOOK']
      end
      args << ENV['FILE']
      PROIEL::Tools.execute('proiel-import', USER_NAME, *args)
    end
  end

  namespace :export do
    desc "Export a PROIEL source text. Options: ID=source_identifier FILE=destination_file"

    task(:proiel => :environment) do
      args = []
      #TODO: [--without-morphtags] [--without-lemmata] [--without-dependencies]
      args << ENV['ID']
      args << ENV['FILE']
      PROIEL::Tools.execute('proiel-export', USER_NAME, *args)
    end
  end
end
