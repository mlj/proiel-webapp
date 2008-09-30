#!/usr/bin/env ruby
#
# import.rb - Import functions
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'proiel/src'

class PROIELXMLDictionaryImport
  # Creates a new importer.
  def initialize(options = {})
  end

  # Reads import data. The data source +file+ may be any URI supported
  # by open-uri.
  def read(file)
    import = PROIEL::Dictionary.new(file)
    import.read_lemmata do |attributes, references|
      begin
        lemma = Lemma.create!(attributes)
        references.each do |reference|
          lemma.dictionary_references.create!(reference)
        end
      rescue Exception => e
        raise "Error creating lemma #{attributes["lemma"]}: #{e}"
      end
    end
  end
end

class SourceImport
  # Creates a new importer.
  #
  # ==== Options
  # book_filter:: If non-empty, only import books with the given code.
  # May be either a string or an array of strings.
  def initialize(options = {})
    options.assert_valid_keys(:book_filter)
    options.reverse_merge! :book_filter => []

    @book_filter = [options[:book_filter]].flatten
  end
end

class PROIELXMLImport < SourceImport
  # Reads import data. The data source +file+ may be any URI supported
  # by open-uri.
  def read(file)
    # We do not need versioning for imports, so disable it.
    Sentence.disable_auditing
    Token.disable_auditing

    import = PROIEL::XSource.new(file)
    STDOUT.puts "Importing source #{import.metadata[:id]}..."

    language = Language.find_by_iso_code(import.metadata[:language])
    source = language.sources.find_by_code(import.metadata[:id])
    raise "Source #{source.metadata[:id]} not found" unless source

    book = nil
    source_division = nil
    sentence_number = nil
    sentence = nil

    args = {}
    args[:books] = @book_filter unless @book_filter.empty?

    import.read_tokens(args) do |form, attributes|
      if book != attributes[:book]
        book = attributes[:book]
        source_division = SourceDivision.find_by_fields("book=#{book}").id
        sentence_number = nil
        STDOUT.puts "Importing book #{book} for source #{source.code}..."
      end

      if sentence_number != attributes[:sentence_number]
        sentence_number = attributes[:sentence_number]
        sentence = source_division.sentences.create!(:sentence_number => sentence_number, 
                                                     :chapter => attributes[:chapter])
      end

#FIXME: this should be moved somewhere else to allow for future extensions. 
#Separate word/lemma-lists?
#            # Now hook up dictionary references,if any
#            if attributes[:references]
#              attributes[:references].split(',').each do |reference|
#                dictionary, entry = reference.split('=')
#                DictionaryReference.find_or_create_by_lemma_id_and_dictionary_identifier_and_entry_identifier(:lemma_id => lemma_id, :dictionary_identifier => dictionary,
#                                                            :entry_identifier => entry)
#              end
#            end

      # Source morphtags do not have to be valid, so we eat the tag without
      # validation.
      morphtag = attributes[:morphtag] ? PROIEL::MorphTag.new(attributes[:morphtag]).to_s : nil

      n = sentence.tokens.create!(
                   :token_number => attributes[:token_number], 
                   :source_morphtag => morphtag,
                   :source_lemma => attributes[:lemma],
                   :form => attributes[:form],
                   :verse => attributes[:verse],
                   :sort => attributes[:sort],
                   :contraction => attributes[:contraction] || false,
                   :emendation => attributes[:emendation] || false,
                   :abbreviation => attributes[:abbreviation] || false,
                   :capitalisation => attributes[:capitalisation] || false,
                   :nospacing => attributes[:nospacing],
                   :presentation_form => attributes[:presentation_form],
                   :presentation_span => attributes[:presentation_span],
                   :foreign_ids => attributes[:foreign_ids])

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
