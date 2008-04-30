require 'tools/unicode-normaliser'
require 'tools/static_tagger'
require 'tools/dictionary_loader'
require 'tools/db_validator'
require 'tools/proiel_export'
require 'tools/proiel_import'
require 'tools/aligner'
require 'jobs'

module PROIEL
  module Tools
    def self.available_tools
      [ "unicode-normaliser" ]
    end

    # Executes a tool.
    def self.execute(tool_name, user_name, *args)
      case tool_name
      when "unicode-normaliser"
        t = UnicodeNormaliser
      when "static-tagger"
        t = StaticTagger
      when "dictionary-loader"
        t = DictionaryLoader
      when "db-validator"
        t = DbValidator
      when "proiel-export"
        t = PROIELExport
      when "proiel-import"
        t = PROIELImport
      when "aligner"
        t = Aligner 
      else
        raise "Unknown tool #{tool_name}"
      end

      source_code = nil

      t = t.new(args)
      execute_job(user_name, t.source, tool_name, args, t.audited?) do |logger, job| 
        t.run!(logger, job)
      end
    end
  end
end

