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
      DictionaryImport.instance.read(ENV['FILE'])
    end
  end

  namespace :text do
    namespace :tei do
      desc "List TEI source texts available for import. Options: TEI_BASE=root TEI directory"
      task(:list => :environment) do
        require 'tei'
        puts "Available sources"
        puts "  %-15s   %-30s %s" % %w(Identifier Filename Title)
        puts "  " + '-' * 70
        TEI::RegisteredSources.instance.sort.each do |identifier, data|
          s = File.exists?(File.join(ENV['TEI_BASE'], data.file_name)) ? '+' : '-'
          puts "  %-15s %s %-30s %s" % [identifier, s, data.file_name, data.title]
        end
      end

      desc "Dump a TEI source text as PROIEL XML. Options: ID=identifier, TEI_BASE=root TEI directory"
      task(:dump => :environment) do
        require 'tei'
        raise "Identifier required" unless ENV['ID']
        File.open("#{ENV['ID']}.xml", "w") do |f|
          f.puts TEI::PerseusAdapter.instance.transform(ENV['ID'], ENV['TEI_BASE'])
        end
      end

      desc "Import a TEI source text. Options: ID=identifier, TEI_BASE=root TEI directory"
      task(:import => :environment) do
        require 'import'

        raise "Identifier required" unless ENV['ID']
        TextImport.instance.read(TEI::PerseusAdapter.instance.transform(ENV['ID'], ENV['TEI_BASE']))
      end

      namespace :import do
        desc "Import a all available TEI source texts. Options: TEI_BASE=root TEI directory"
        task(:all => :environment) do
          require 'import'

          TEI::RegisteredSources.instance.sort.each do |identifier, data|
            if File.exists?(File.join(ENV['TEI_BASE'], data.file_name))
              unless Source.find_by_code(identifier)
                TextImport.instance.read(TEI::PerseusAdapter.instance.transform(identifier, ENV['TEI_BASE']))
              else
                STDERR.puts "Source #{identifier} already defined. Ignoring."
              end
            else
              STDERR.puts "Cannot find TEI file for #{identifier}. Ignoring."
            end
          end
        end
      end
    end

    desc "Validate a PROIEL source text. Options: FILE=data_file"
    task(:validate => :environment) do
      raise "Filename required" unless ENV['FILE']
      `xmllint --schema #{File.join(RAILS_ROOT, 'lib', 'text.xsd')} --noout #{ENV['FILE']}`
    end

    desc "Import a PROIEL source text. Options: FILE=data_file"
    task(:import => :environment) do
      require 'import'

      raise "Filename required" unless ENV['FILE']
      File.open(ENV['FILE']) { |f| TextImport.instance.read(f) }
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

    desc "Import a source text in legacy format. Options: FILE=data_file, FORMAT={proiel}"
    task(:legacy_import => :environment) do 
      require 'legacy_import'
      raise "Filename require" unless ENV['FILE']
      format = ENV['FORMAT']
      format ||= :proiel
      li = LegacyImport.new(:proiel)
      li.read(ENV['FILE'])
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

    desc "Export info statuses. Options: FILE=csv_file. Optional options: SOURCE_DIVISION=source_division_id"
    task(:export => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument FILE" unless file_name

      sd = ENV['SOURCE_DIVISION']
      i = InfoStatusesImportExport.new(sd)
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
