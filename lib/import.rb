#!/usr/bin/env ruby
#
# proiel_import.rb - PROIEL database import
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
# $Id: $
#
require 'simplepullparser'
require 'jobs'

class PROIELImport < Task
  def initialize(data_file, book_filter = nil)
    @data_file = data_file 
    @book_filer = book_filter

    super('import', false, false)
  end

  protected

  def run!(logger)
    Sentence.disable_auditing
    Token.disable_auditing

    metadata, new_tokens = PROIEL::read_source2(@data_file, { :filters => @filters })

    source = Source.find_by_code_and_language(metadata[:id], metadata[:language])
    unless source
      logger.info { "* Creating new source #{metadata[:id]}..." }
      source = Source.new(:code => metadata[:id])
      [:title, :language, :edition, :source, :editor, :url].each { |e| source[e] = metadata[e] }
      source.save!
    else
      logger.warn { "* Source #{metadata[:id]} exists. Old data associated with source will not be removed and meta-data will not be overwritten..." }
    end

    # Deal with the tokens
    book = nil
    book_id = nil
    sentence_number = nil
    sentence = nil

    new_tokens.each do |form, attributes|
      if book != attributes[:book]
        book = attributes[:book]
        book_id = Book.find_by_code(book).id
        sentence_number = nil
        logger.info { "* Working on book #{book}..." }
      end

      if sentence_number != attributes[:sentence_number]
        sentence_number = attributes[:sentence_number]
        sentence = source.sentences.create!(:sentence_number => sentence_number, 
                                    :book_id => book_id,
                                    :chapter => attributes[:chapter])
      end

      # First, handle the lemma, if any
#          if attributes[:lemma]
#            lemma, variant = attributes[:lemma].split('#')
#
#            l = Lemma.find_or_create_by_lemma_and_variant_and_language(lemma, variant, metadata[:language])
#
#            lemma_id = l.id
#
#            # Now hook up dictionary references,if any
#            if attributes[:references]
#              attributes[:references].split(',').each do |reference|
#                dictionary, entry = reference.split('=')
#                DictionaryReference.find_or_create_by_lemma_id_and_dictionary_identifier_and_entry_identifier(:lemma_id => lemma_id, :dictionary_identifier => dictionary,
#                                                            :entry_identifier => entry)
#              end
#            end
#          end

      # Then, add the token
      if attributes[:morphtag]
        m = PROIEL::MorphTag.new(attributes[:morphtag])
        if m.valid?
          morphtag = m.to_s
        else
          logger.error { "Invalid morphtag #{m} encountered." }
          morphtag = nil
        end
      end

      sentence.tokens.create!(
                   :token_number => attributes[:token_number], 
                   :source_morphtag => morphtag,
                   :source_lemma => attributes[:lemma],
                   :form => form, 
                   :verse => attributes[:verse], 
                   :composed_form => attributes[:composed_form],
                   :sort => attributes[:sort])

      if (attributes[:relation] or attributes[:head]) and not dependency_warned
        logger.warn { "Import of dependency structures not supported. Ignoring." }
        dependency_warned = true
      end
    end
  end
end
