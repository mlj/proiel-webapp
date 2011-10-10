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

  namespace :text do
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

    desc "Export a PROIEL source text. Optional options: ID=source_identifier FORMAT={proiel|maltxml|tigerxml|tiger2} MODE={all|reviewed} DIRECTORY=destination_directory INFO={semtags|info|both} SOURCE_DIVISION=source division title regexp REMOVE_CYCLES={none|heads|all}"
    task(:export => :environment) do
      source = ENV['ID']
      format = ENV['FORMAT']
      format ||= 'proiel'
      source_division = Regexp.new(ENV['SOURCE_DIVISION']) if ENV['SOURCE_DIVISION']
      mode = ENV['MODE']
      mode ||= 'all'
      directory = ENV['DIRECTORY']
      directory ||= DEFAULT_EXPORT_DIRECTORY
      info = ENV['INFO']
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
      when 'tiger2'
        klass = Tiger2Export
        suffix = '-tiger2'
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

      options[:cycles] = ENV['REMOVE_CYCLES']
      options[:cycles] ||= 'none'

      case info
      when 'semtags'
        options[:sem_tags] = true
      when 'info'
        options[:info] = true
      when 'both'
        options[:sem_tags] = true
        options[:info] = true
      else
        raise "Invalid info" if info
      end

      if options[:sem_tags]
        raise "Information structure not available for maltxml" if format == 'maltxml'
      end

      if options[:info]
        raise "Semantic tags not available for maltxml" if format == 'maltxml'
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
        options[:source_division] = source.source_divisions.select { |sd| sd.title =~ source_division }.map(&:id) if source_division
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

  namespace :bilingual_dictionary do
    desc "Create a dictionary based on collocation measures. Options: SOURCE=source_id, FORMAT=human or id, FILE=outfile, METHOD=association score method"
    task(:create => :myenvironment) do
      require 'alignment/dictionary_creator'
      source = ENV['SOURCE'].to_i
      raise "Missing argument" unless source
      format = ENV['FORMAT'].to_sym if ENV['FORMAT']
      format ||= :id
      file = ENV['FILE']
      raise "Missing argument" unless file
      method = ENV['METHOD'].to_sym if ENV['METHOD']
      method ||= :zvtuuf
      dc = DictionaryCreator.new(source, format, file, method)
      dc.execute
    end
  end

  namespace :token_alignments do
    desc "Set token alignments. Options: SOURCE=source_id or SOURCE_DIVISION=source_division_id, FORMAT={human|csv|db}, FILE=outfile DICTIONARY=dictionary file"
    task(:set => :myenvironment) do
      require 'alignment/token_aligner'
      format = ENV['FORMAT']
      format ||= 'db'
      file_name = ENV['FILE']
      file_name ||= STDOUT
      raise "Missing argument DICTIONARY" unless ENV['DICTIONARY']
      dictionary = Lingua::Collocations.new(File.join(RAILS_ROOT, "lib", ENV['DICTIONARY']))

      source = ENV['SOURCE']
      source_division = ENV['SOURCE_DIVISION']
      raise "You can't specify both SOURCE and SOURCE_DIVISION" if source and source_division

      if source_division
        if source_division.include?('-')
          source_division = (source_division.split('-')[0].to_i)..(source_division.split('-')[1].to_i)
        else
          source_division = [source_division]
        end
        sds = source_division.map { |sd| SourceDivision.find(sd) }
      elsif source
        sds = Source.find(source).source_divisions
      else
        raise "Missing argument"
      end

      ta = TokenAligner.new(dictionary, format, sds, file_name)
      ta.execute
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
    desc "Import info statuses. Options: FILE=csv_file."
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = InfoStatusesImportExport.new
      i.read(file_name)
    end

    desc "Delete info statuses. Options: SOURCE_DIVISION=source_division_id"
    task(:delete => :myenvironment) do
      sd = ENV['SOURCE_DIVISION']
      raise "Missing argument SOURCE_DIVISION" unless sd

      Token.find(:all,
                 :conditions => ["empty_token_sort = 'P' AND sentences.source_division_id = ? ", sd],
                 :include => :sentence).each do |t|
        t.destroy
      end


      Token.find(:all,
                 :conditions => ["info_status IS NOT NULL AND sentences.source_division_id = ?", sd],
                 :include => :sentence).each do |t|
        STDERR.puts "Removing info_status from #{t} (#{t.id})"
        t.info_status = nil
        t.antecedent_id = nil
        t.save!
      end
    end

    desc "Export info statuses. Options: FILE=csv_file SOURCE_DIVISION=source_division_id FORMAT={csv|xml}"
    task(:export => :myenvironment) do
      file_name = ENV['FILE']
      raise "Missing argument FILE" unless file_name
      sd = ENV['SOURCE_DIVISION']

      case ENV['FORMAT']
      when 'csv'
        require 'import_export'
        klass = InfoStatusesImportExport
      when 'xml'
        require 'info_statuses_xml_export'
        klass = InfoStatusesXMLExport
      else
        raise "Unknown format"
      end

      i = klass.new(sd)
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
