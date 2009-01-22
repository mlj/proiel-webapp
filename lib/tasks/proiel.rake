DEFAULT_EXPORT_DIRECTORY = File.join(RAILS_ROOT, 'public', 'exports')

namespace :proiel do
  task(:myenvironment => :environment) do
    require 'jobs'
  end

  desc "Validate PROIEL database"
  task(:validate => ["db:validate", :myenvironment]) do
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
      File::copy(File.join(RAILS_ROOT, 'lib', 'proiel', 'morphology.xml'),
                 File.join(directory, 'morphology.xml'))
      File::copy(File.join(RAILS_ROOT, 'lib', 'proiel', 'relations.xml'),
                 File.join(directory, 'relations.xml'))
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

    desc "Harmonize the POS of all tokens belonging to a lemma to the POS of the lemma. Options: LEMMA=lemma_id"
    task(:harmonize => :myenvironment) do
      lemma = ENV['LEMMA']
      raise "Lemma identifier required" unless lemma
      raise "Unable to find lemma" unless Lemma.exists?(lemma)
      new_pos = Lemma.find(lemma).pos
      raise "Lemma does not have a part of speech" if new_pos.blank?
      require 'mass_assignment'
      Token.transaction do
	mt = MassTokenAssignment.new
	mt.reassign_morphology!(:major, nil, new_pos.first, 'morphtag', lemma)
	mt.reassign_morphology!(:minor, nil, new_pos.last, 'morphtag', lemma)
      end
    end

    desc "Reassign a morphological field. Options: FIELD=field, FROM=from_value, TO=to_value. Optional options: LEMMA=lemma_id"
    task(:reassign => :myenvironment) do
      field, from_value, to_value, lemma = ENV['FIELD'], ENV['FROM'], ENV['TO'], ENV['LEMMA']
      raise "Missing argument" unless field and from_value and to_value
      require 'mass_assignment'
      Token.transaction do
        mt = MassTokenAssignment.new
        mt.reassign_morphology!(field, from_value, to_value, 'morphtag', lemma)
        mt.reassign_morphology!(field, from_value, to_value, 'source_morphtag', lemma)
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
