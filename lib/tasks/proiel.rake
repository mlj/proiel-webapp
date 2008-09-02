#TODO
USER_NAME='mlj'

DEFAULT_EXPORT_DIRECTORY = File.join(RAILS_ROOT, 'public', 'exports')

namespace :proiel do
  task(:myenvironment => :environment) do
    require 'jobs'
  end

  desc "Validate PROIEL database"
  task(:validator => :myenvironment) do
    require 'validation'

    v = Validator.new
    v.execute!(USER_NAME)
  end

  desc "Force manual morphological rules. SOURCES=source_identifier[,..]"
  task(:manual_tagger => :myenvironment) do
    require 'tools/manual_tagger'
  
    raise "Source identifiers required" unless ENV['SOURCES']

    source_ids = ENV['SOURCES'].split(',').collect { |s| Source.find_by_code(s) }

    v = ManualTagger.new(source_ids)
    v.execute!(USER_NAME)
  end

  desc "Import a PROIEL source text. Options: FILE=data_file BOOK=book_filter" 
  task(:import => :environment) do
    require 'import'

    raise "Filename required" unless ENV['FILE']
    e = ENV['BOOK'] ? PROIELXMLImport.new(:book_filter => ENV['BOOK']) : PROIELXMLImport.new
    e.read(ENV['FILE'])
  end

  namespace :import do
    desc "Import a PROIEL dictionary. Options: FILE=data_file" 
    task(:dictionary => :environment) do
      require 'import'

      raise "Filename required" unless ENV['FILE']
      PROIELXMLDictionaryImport.new.read(ENV['FILE'])
    end
  end

  desc "Export a PROIEL source text. Options: ID=source_identifier"
  task(:export => :environment) do
    require 'export'

    source = Source.find_by_code(ENV['ID'])
    raise "Source not found" unless source
    e = PROIELXMLExport.new(source)
    e.write("#{source.code}.xml")
  end

  namespace :export do
    namespace :maltxml do
      require 'export'

      desc "Export a PROIEL source text as MaltXML. Options: ID=source_identifier"
      task(:all => :myenvironment) do
        source = Source.find_by_code(ENV['ID'])
        raise "Source not found" unless source
        e = MaltXMLExport.new(source)
        e.write("#{source.code}-malt.xml")
      end
    end

    namespace :tigerxml do
      require 'export'

      desc "Export a PROIEL source text as TigerXML. Options: ID=source_identifier"
      task(:all => :myenvironment) do
        source = Source.find_by_code(ENV['ID'])
        raise "Source not found" unless source
        e = TigerXMLExport.new(source)
        e.write("#{source.code}-tiger.xml")
      end
    end

    namespace :all do
      require 'export'

      desc "Export all PROIEL source texts with all publicly available data (i.e. reviewed data)."
      task(:public => :myenvironment) do
        Dir::mkdir(DEFAULT_EXPORT_DIRECTORY) unless File::directory?(DEFAULT_EXPORT_DIRECTORY)
        File::copy(File.join(RAILS_ROOT, 'data', 'text.xsd'), 
                   File.join(DEFAULT_EXPORT_DIRECTORY, 'text.xsd'))
        File::copy(File.join(RAILS_ROOT, 'lib', 'proiel', 'morphology.xml'), 
                   File.join(DEFAULT_EXPORT_DIRECTORY, 'morphology.xml'))
        File::copy(File.join(RAILS_ROOT, 'lib', 'proiel', 'relations.xml'), 
                   File.join(DEFAULT_EXPORT_DIRECTORY, 'relations.xml'))
        Source.find(:all).each do |source|
          e = PROIELXMLExport.new(source, :reviewed_only => true)
          e.write(File.join(DEFAULT_EXPORT_DIRECTORY, "#{source.code}.xml"))

          e = TigerXMLExport.new(source, :reviewed_only => true)
          e.write(File.join(DEFAULT_EXPORT_DIRECTORY, "#{source.code}-tiger.xml"))

          e = MaltXMLExport.new(source, :reviewed_only => true)
          e.write(File.join(DEFAULT_EXPORT_DIRECTORY, "#{source.code}-malt.xml"))
        end
      end
    end
  end

  namespace :reassign do
    desc "Reassign a morphological field. Options: FIELD=field, FROM=from_value, TO=to_value"
    task(:morphology => :myenvironment) do
      field, from_value, to_value = ENV['FIELD'], ENV['FROM'], ENV['TO']
      raise "Missing argument" unless field and from_value and to_value

      require 'mass_assignment'
      Token.transaction(User.find_by_login(USER_NAME)) do #FIXME
        mt = MassTokenAssignment.new
        mt.reassign_morphology!(field, from_value, to_value)
      end
    end
  end

  namespace :history do
    namespace :prune do
      desc "Prune an attribute from history. Options: MODEL=model_name, ATTRIBUTE=attribute_name"
      task(:attribute => :myenvironment) do
        model_name, attribute_name = ENV['MODEL'], ENV['ATTRIBUTE']
        raise "Missing argument" unless model_name and attribute_name

        require 'mass_assignment'
        at = MassAuditAssignment.new
        at.remove_attribute!(model_name, attribute_name)
      end
    end
  end

  namespace :semantic_tags do
    desc "Import semantic tags. Options: FILE=csv_file"
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = SemanticTagImportExport.new
      i.read(file_name)
    end

    desc "Export semantic tags. Options: FILE=csv_file"
    task(:export => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = SemanticTagImportExport.new
      i.write(file_name)
    end
  end
end
