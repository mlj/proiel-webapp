#!/usr/bin/env ruby
#
# legacy_import.rb - Import functions for old style proiel formatted texts
#
# Written by Marius L. Jøhndal, 2007, 2008.
# Written by Dag Haug, 2009

require 'proiel/legacy_src'

class LegacyImport

  def initialize(format = :proiel)
    @format = format
  end

  # Reads import data. The data source +file+ may be any URI supported
  # by open-uri.
  def read(file)
    # We do not need versioning for imports, so disable it.
    Sentence.disable_auditing
    Token.disable_auditing
    
    case @format
    when :proiel
      import = PROIEL::LegacySource.new(file)
    else
      raise "Unknown format"
    end
    
    STDOUT.puts "Importing source #{import.metadata[:id]}..."
    STDOUT.puts " * Identifier: #{import.metadata[:id]}"
    STDOUT.puts " * Language: #{import.metadata[:language]}"
    
    source = Source.find_by_language_and_code(import.metadata[:language], import.metadata[:id])
    raise "Source #{import.metadata[:id]} not found" unless source
    
    sd = nil
    sentence_number = nil
    sentence = nil
    
    import.read_tokens(source.tracked_references) do |form, attributes|
      if sd.nil? or sd.title != attributes[:sd_title]
                
        sd = source.source_divisions.create do |s| 
          s.position = source.source_divisions.last ? source.source_divisions.last.position + 1 : 0
          s.title = attributes[:sd_title]
          s.abbreviated_title = attributes[:sd_abbreviated_title]
          s.reference_fields = attributes[:reference_fields].slice(*source.tracked_references["source_division"]) 
          s.presentation = attributes[:source_division_presentation].join.gsub(/(<s>)([^<]*)(<\/s>)/, '\2').gsub(/(<w>)([^<]*)(<\/w>)/, '\2').gsub(/(<pc>)([^<]*)(<\/pc>)/, '\2').gsub(/(<\/*)(seg>)/, '\1w>')
        end
        
        sentence_number = nil
        STDOUT.puts "Importing source division #{sd.title} for source #{source.code}..."
      end

      # For the sentence presentation we remove any potentially nested
      # elements and then remove superfluous spacing that may have
      # arisen due tot he removal
      if sentence_number != attributes[:sentence_number]
        sentence_number = attributes[:sentence_number]
        sentence = sd.sentences.create!(:sentence_number => sentence_number, 
                                        :presentation => attributes[:sentence_presentation].gsub(/(<\/*)(seg>)/, '\1w>').gsub(/(<\/*)(expan[^>]*>)/, '\1w>').gsub(/<\/*add[^>]*>/,"").gsub(/<\/*segmented[^>]*>/, "").gsub(/<\/*del[^>]*>/,"").gsub(/<s> <\/s>(<s> <\/s>)+/, "<s> <\/s>")


)
        sentence.reference_fields = attributes[:reference_fields].slice(*source.tracked_references["sentence"])
        sentence.save!
      end

      # Source morphtags do not have to be valid, so we eat the tag without
      # validation.
      morphology = attributes[:morphtag]


      n = sentence.tokens.create!(:token_number => attributes[:token_number], 
                                  :source_morphology => morphology,
                                  :source_lemma => attributes[:lemma],
                                  :form => attributes[:form],
                                  :foreign_ids => attributes[:foreign_ids]
                                  )
      n.reference_fields = attributes[:reference_fields].slice(*source.tracked_references["token"])
      n.save!

      if attributes[:notes]
        attributes[:notes].each do |note|
          n.notes.create! :originator => ImportSource.find_or_create_by_tag(:tag => note[:origin], :summary => note[:origin]), :contents => note[:contents]
        end
      end
      
      if (attributes[:relation] or attributes[:head]) and not dependency_warned
        STDERR.puts "Dependency structures cannot be imported. Ignoring."
        dependency_warned = true
      end
    end
  end
end
