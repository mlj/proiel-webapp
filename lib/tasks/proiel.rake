require 'fileutils'

desc "Work the job queue"
task :work_jobs => :environment do
  database_checker = Proiel::Jobs::DatabaseChecker.new

  while true do
    database_checker.run!
    sleep 1.hour
  end
end

namespace :proiel do
  task(:myenvironment => :environment) do
  end

  desc "Validate PROIEL database using extra (non-model) validations"
  task(:validate => [:myenvironment]) do
    require 'validation'

    v = Validator.new
    v.execute!
  end

  namespace :text do
    desc "Import a PROIEL source text. Options: FILE=data_file"
    task(:import => :environment) do
      options = {}

      case ENV['FORMAT']
      when NilClass, 'proiel'
        klass = PROIELXMLImporter
        suffix = '.xml'
      when 'json'
        klass = JSONImporter
        suffix = '.json'
      when 'text'
        klass = TextImporter
        suffix = '.txt'
      else
        raise "Invalid format"
      end

      raise "Filename required" unless ENV['FILE']
      klass.new.read(ENV['FILE'])
    end

    desc "Export a PROIEL source text. Optional options: ID=database ID of source (FORMAT={proiel|conll|tigerxml|tiger2} MODE={all|reviewed} DIRECTORY=destination_directory INFO=semtags SOURCE_DIVISION=source division title regexp REMOVE_CYCLES={none|heads|all})"
    task(:export => :environment) do
      options = {}

      case ENV['FORMAT']
      when NilClass, 'proiel'
        klass = PROIELXMLExporter
        suffix = '.xml'
      when 'conll'
        klass = CoNLLExporter
        suffix = '.conll'
      when 'tigerxml'
        klass = TigerXMLExporter
        suffix = '.tiger'
      when 'tiger2'
        klass = Tiger2Exporter
        suffix = '.tiger2'
      when 'text'
        klass = TextExporter
        suffix = '.txt'
      when 'json'
        klass = JSONExporter
        suffix = '.json'
      else
        raise "Invalid format"
      end

      case ENV['MODE']
      when 'reviewed'
        options = { :reviewed_only => true }
      when NilClass, 'all'
      else
        raise "Invalid mode"
      end

      options[:cycles] = ENV['REMOVE_CYCLES'] || 'none'

      case ENV['INFO']
      when NilClass, 'none'
      when 'semtags'
        options[:sem_tags] = true
      when 'info' # ignore for backwards compatibility
      when 'both' # for backwards compatibility
        options[:sem_tags] = true
      else
        raise "invalid value for INFO"
      end

      # Prepare destination directory
      directory = ENV['DIRECTORY'] || Proiel::Application.config.export_directory_path
      Dir::mkdir(directory) unless File::directory?(directory)

      # Find sources and iterate them
      sources = ENV['ID'] ? Source.find_all_by_id(ENV['ID']) : Source.all

      sources.each do |source|
        file_name = File.join(directory, "#{source.human_readable_id}#{suffix}")

        if ENV['SOURCE_DIVISION']
          options[:source_division] = source.source_divisions.select { |sd| sd.title =~ Regexp.new(ENV['SOURCE_DIVISION']) }.map(&:id)
        end

        begin
          klass.new(source, options).write(file_name)
        rescue Exception => e
          STDERR.puts "Error exporting text #{source.human_readable_id} using #{klass}: #{e}"
          STDERR.puts e.backtrace.join("\n")
        end
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

  namespace :morphology do
    desc "Force manual morphological rules. Options: SOURCES=source_identifier[,..]"
    task(:force_manual_tags => :myenvironment) do
      sources = ENV['SOURCES']
      raise "Source identifiers required" unless sources

      require 'tools/manual_tagger'
      source_ids = sources.split(',').collect { |s| Source.find(s) }
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
      dictionary = Lingua::Collocations.new(Rails.root.join("lib", ENV['DICTIONARY']))

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

    desc "Read token alignments from file. Options: FILE=alignment csv file"
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = TokenAlignmentImportExport.new
      i.read(file_name)
    end
    
    desc "Write token alignments to file. Options: FILE = outfile"
    task(:export => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = TokenAlignmentImportExport.new
      i.write(file_name)
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
                 :conditions => ["information_status_tag IS NOT NULL AND sentences.source_division_id = ?", sd],
                 :include => :sentence).each do |t|
        STDERR.puts "Removing information_status_tag from #{t} (#{t.id})"
        t.information_status_tag = nil
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

  namespace :semantic_relations do
    desc "Import semantic relatinos. Options: FILE=csv_file"
    task(:import => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = SemanticRelationImportExport.new
      i.read(file_name)
    end

    desc "Export semantic relations. Options: FILE=csv_file"
    task(:export => :myenvironment) do
      require 'import_export'
      file_name = ENV['FILE']
      raise "Missing argument" unless file_name

      i = SemanticRelationImportExport.new
      i.write(file_name)
    end

    desc "Delete semantic relations. Options: SOURCE_DIVISION=source_division_id, TYPE=semantic_relation_type"
    task(:delete => :myenvironment) do
      sd = ENV['SOURCE_DIVISION'].to_i
      raise "Missing argument SOURCE_DIVISION" unless sd
      type = SemanticRelationType.find_by_tag(ENV['TYPE']).id
      raise "Missing semantic relation type" unless type
      SemanticRelation.find(:all,
                 :conditions => ["semantic_relation_tags.semantic_relation_type_id = ?", type],
                 :include => :semantic_relation_tag).each do |sr|
                   if sr.controller.sentence.source_division_id == sd
                     STDERR.puts "Destroying tag #{sr}"
                     sr.destroy
                   end
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
