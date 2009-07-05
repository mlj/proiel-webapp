DEFAULT_EXPORT_DIRECTORY = File.join(RAILS_ROOT, 'public', 'exports')

namespace :proiel do
  task(:myenvironment => :environment) do
    require 'jobs'
  end

  desc "Validate PROIEL database using extra (non-model) validations"
  task(:validate => [:myenvironment]) do
    require 'validation'

    v = Validator.new
    v.execute!
  end

  namespace :dictionary do
    desc "Import a PROIEL dictionary. Options: FILE=data_file"
    task(:import => :environment) do
      require 'import'

      raise "Filename required" unless ENV['FILE']
      PROIELXMLDictionaryImport.new.read(ENV['FILE'])
    end
  end

  namespace :text do
    desc "Validate a PROIEL source text. Options: FILE=data_file"
    task(:validate => :environment) do
      raise "Filename required" unless ENV['FILE']
      `xmllint --schema #{File.join(RAILS_ROOT, 'lib', 'text.xsd')} --noout #{ENV['FILE']}`
    end

    desc "Import a PROIEL source text. Options: FILE=data_file BOOK=book_filter"
    task(:import => :environment) do
      require 'import'

      raise "Filename required" unless ENV['FILE']
      e = ENV['BOOK'] ? PROIELXMLImport.new(:book_filter => ENV['BOOK']) : PROIELXMLImport.new
      e.read(ENV['FILE'])
    end

    desc "Export a PROIEL source text. Optional options: ID=source_identifier FORMAT={proiel|maltxml|tigerxml} MODE={all|reviewed} DIRECTORY=destination_directory"
    task(:export => :environment) do
      source = ENV['ID']
      format = ENV['FORMAT']
      format ||= 'proiel'
      mode = ENV['MODE']
      mode ||= 'all'
      directory = ENV['DIRECTORY']
      directory ||= DEFAULT_EXPORT_DIRECTORY
      require 'export'

      case format
      when 'maltxml'
        klass = MaltXMLExport
        suffix = '-malt'
      when 'tigerxml'
        klass = TigerXMLExport
        suffix = '-tiger'
      when 'proiel'
        klass = PROIELXMLExport
        suffix = ''
      else
        raise "Invalid format"
      end

      case mode
      when 'all'
        options = {}
      when 'reviewed'
        options = { :reviewed_only => true }
      else
        raise "Invalid mode"
      end

      if source
        sources = Source.find_all_by_code(source)
      else
        sources = Source.find(:all)
      end

      raise "Unable to find any sources to export" if sources.empty?

      # Prepare destination directory and ancillary files
      Dir::mkdir(directory) unless File::directory?(directory)

      sources.each do |source|
        e = klass.new(source, options)
        e.write(File.join(directory, "#{source.code}#{suffix}.xml"))
      end
    end
  end

  namespace :schemata do
    desc "Export PROIEL schemata. Optional options: DIRECTORY=destination_directory"
    task(:export) do
      directory = ENV['DIRECTORY']
      directory ||= DEFAULT_EXPORT_DIRECTORY

      Dir::mkdir(directory) unless File::directory?(directory)
      File::copy(File.join(RAILS_ROOT, 'lib', 'text.xsd'),
                 File.join(directory, 'text.xsd'))
    end
  end

  namespace :morphology do
    desc "Force manual morphological rules. Options: SOURCES=source_identifier[,..]"
    task(:force_manual_tags => :myenvironment) do
      sources = ENV['SOURCES']
      raise "Source identifiers required" unless sources

      require 'tools/manual_tagger'
      source_ids = sources.split(',').collect { |s| Source.find_by_code(s) }
      v = ManualTagger.new(source_ids)
      v.execute!
    end

    desc "Reassign a source_morphology field. Options: FIELD=field, FROM=from_value, TO=to_value."
    task(:reassign => :myenvironment) do
      field, from_value, to_value = ENV['FIELD'], ENV['FROM'], ENV['TO']
      raise "Missing argument" unless field and from_value and to_value
      require 'mass_assignment'
      Token.transaction do
        mt = MassTokenAssignment.new
        mt.reassign_source_morphology!(field, from_value, to_value)
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

  namespace :dependency_alignments do
    desc "Import dependency alignments. Options: FILE=csv_file"
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = DependencyAlignmentImportExport.new
      i.read(file_name)
    end
  end

  namespace :info_statuses do
    desc "Import info statuses. Options: FILE=csv_file. Optional options MODE={overwrite|recreate}"
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name
      execute("UPDATE tokens SET info_status = NULL, antecedent_dist_in_words = NULL, antecedent_dist_in_sentences = NULL, antecedent_id = NULL WHERE info_status is not null") if ENV['MODE'] == "recreate"
      overwrite = false
      overwrite = true if ENV['MODE'] == "overwrite"
      i = InfoStatusesImportExport.new
      i.read(file_name)
    end

    desc "Export info statuses. Options: FILE=csv_file. Optional options: SD=source_division_id"
    task(:export => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = InfoStatusesImportExport.new
      i.write(file_name)
    end
  end

  namespace :notes do
    desc "Import notes. Options: FILE=csv_file."
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      NoteImportExport.new.read(file_name)
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

  namespace :inflections do
    desc "Import inflections. Options: FILE=csv_file"
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = InflectionsImportExport.new
      i.read(file_name)
    end

    desc "Export inflections. Options: FILE=csv_file"
    task(:export => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = InflectionsImportExport.new
      i.write(file_name)
    end
  end
end
