#!/usr/bin/env ruby
#
# source.rb - PROIEL source file manipulation functions
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'unicode'
require 'open-uri'
require 'hpricot'
require 'builder'

module PROIEL
  class Dictionary
    def initialize(uri)
      doc = Hpricot.XML(open(uri))

      t = doc.at("dictionary")
      @id = t.attributes["id"]
      @language = t.attributes["lang"].to_sym

      @entries = Hash[*(doc/:entries/:entry).collect { |b| [b.attributes["lemma"], b] }.flatten]
    end

    # Reads entries from a source.
    def read_lemmata(options = {})
      @entries.values.each do |entry|
        references = (entry/:references/:reference).collect(&:attributes)
        attributes = Hash[*entry.attributes.collect { |k, v| [k.gsub('-', '_').to_sym, v] }.flatten]
        
        yield attributes.merge({ :language => @language }), references
      end
    end
  end

  # FIXME: moronic Rails (documentation). This clashes with ::Source
  # in the webapp and causes all sorts of weird problems. Why?
  class XSource
    def initialize(uri)
      doc = Hpricot.XML(open(uri))

      @metadata = {}

      t = doc.at("text")
      @metadata[:id] = t.attributes["id"]
      @metadata[:language] = t.attributes["lang"].to_sym

      m = (doc/:text).at("metadata")
      ["title", "edition", "source", "editor", "url"].collect { |k| [k, m.at(k)] }.each do |k, e|
        @metadata[k.to_sym] = e.inner_html if e
      end

      raise "Invalid source: No metadata found" if @metadata.empty?

      @metadata.merge!({ :filename => uri })

      @sequence = []
      @books = Hash[*(doc/:text/:book).collect { |b| @sequence << b.attributes["name"]; [b.attributes["name"], b] }.flatten]

      raise "Invalid source: No books found in source" if @books.empty?

      puts "Registered books #{@books.keys.join(',' )}..."
    end

    # Returns the list of books defined in the source. The list is
    # returned as an array of book codes.
    def books
      # This could of course be @books.keys, but keeping this
      # sorted the way it was read makes it a lot easier to
      # produce predictable XML files. This in turn makes it 
      # easier to diff the resulting files.
      @sequence
    end

    # Returns the meta-data for the source. The meta-data is returned
    # as a hash with keys corresponding to elements in the meta-data
    # header, and including the source identifier, language tag
    # and filename.
    attr_reader :metadata

    # Reads one or more books from a source.
    #
    # ==== Options
    # books: A list of books to read.
    def read_tokens(options = {})
      sentence_number = nil
      token_number = nil

      books = options[:books] ? @books.values_at(*options[:books]) : @books.values

      raise "No books matched filter" if books.empty?

      books.each do |b|
        sentence_number = 0

        (b/:sentence).each do |s|
          sentence_number += 1
          token_number = 0

          (s/:token).each do |t|
            token_number += 1

            a = { :book => b.attributes["name"], 
                  :sentence_number => sentence_number, 
                  :token_number => token_number, }
            (t/:notes/:note).each do |n|
              a[:notes] ||= []
              a[:notes] << { :origin => n.attributes['origin'], :contents => n.inner_html }
            end

            t.attributes.each_pair do |k, v|
              case k
              when 'form', 'references', 'lemma', 'morphtag'
                a[k.to_sym] = v
              when 'chapter', 'verse'
                a[k.to_sym] = v.to_i
              when 'presentation-span'
                a[:presentation_span] = v.to_i
              when 'presentation-form'
                a[:presentation_form] = v
              when 'contraction', 'emendation', 'abbreviation', 'capitalisation'
                a[k.to_sym] = (v == 'true' ? true : false)
              when 'sort', 'nospacing'
                a[k.to_sym] = v.gsub(/-/, '_').to_sym
              when 'foreign-ids'
                a[:foreign_ids] = v
              else
                raise "Invalid source: token has unknown attribute #{k}"
              end
            end

            yield a[:form], a
          end
        end
      end
    end
  end

  public

  class Writer
    protected

    def sym_to_attr(sym)
      sym.to_s.gsub('_', '-')
    end

    def hash_to_sorted_key_value_list(hash)
      if hash.empty?
        nil
      else
        hash.sort { |x, y| x.to_s <=> y.to_s }.collect { |k, v| v.nil? ? nil : "#{k}=#{v.gsub(',', '\\,')}" }.compact.join(',')
      end
    end

    def hash_sym_to_attr(hash)
      Hash[*hash.collect { |k, v| [sym_to_attr(k), v] }.flatten]
    end
  end

  # A PROIEL XML dictionary writer.
  class DictionaryWriter < Writer
    def initialize(file, dictionary_id, language, metadata = {})
      builder = Builder::XmlMarkup.new(:target=> file, :indent => 2)
      builder.instruct! :xml, :version => "1.0", :encoding => "utf-8"
      builder.dictionary :id => dictionary_id, :lang => language do |b|
        b.metadata do |m|
          [:short_title, :long_title, :base_source_editor, :base_source_year, :electronic_source_editor, :electronic_source_version, :electronic_source_url].each { |k| m.tag!(sym_to_attr(k), metadata[k]) if metadata[k] }
        end

        b.entries do |e|
          @entries = e

          yield self
        end
      end
    end

    def write_entry(attributes = {})
      attributes, sub_elements = translate_attributes(attributes)
      @entries.entry(attributes) do |entry|
        entry.senses do |senses|
          sub_elements[:senses].each { |n| senses.sense({ :lang => n[:lang] }, n[:text]) }
        end if sub_elements[:senses]

        entry.notes do |notes|
          sub_elements[:notes].each { |n| notes.note({ :origin => n[:origin] }, n[:text]) }
        end if sub_elements[:notes]

        entry.references do |references|
          sub_elements[:references].each { |n| references.reference(n) }
        end if sub_elements[:references]
      end
    end

    private

    def translate_attributes(attributes = {})
      r = {}
      sub_elements = {}

      attributes.each_pair do |k, v|
        next if v.nil?

        case k
        when :lemma
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(String)
          r[k] = Unicode.normalize_C(v)
        when :pos
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(PROIEL::MorphTag)
          r[k] = v.to_abbrev_s unless v.empty?
        when :sort_key
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(String)
          r[k] = v
        when :variant
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(Integer)
          r[k] = v
        when :unclear, :reconstructed, :conjecture, :inflected
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(TrueClass) or v.is_a?(FalseClass)
          r[k] = 'true' if v
        when :references, :notes, :senses
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(Array)
          sub_elements[k] = v unless v.empty?
        when :foreign_ids
          raise ArgumentError, "invalid value for attribute #{k}" unless v.is_a?(Hash)
          v = hash_to_sorted_key_value_list(v)
          r[k] = v if v
        else
          raise ArgumentError, "invalid attribute #{k}"
        end
      end

      [hash_sym_to_attr(r), sub_elements]
    end
  end

  WORD_TOKEN_SORTS = [ :text ].freeze
  EMPTY_TOKEN_SORTS = [ :empty_dependency_token ].freeze
  PUNCTUATION_TOKEN_SORTS = [ :punctuation ].freeze
  NON_EMPTY_TOKEN_SORTS = WORD_TOKEN_SORTS + PUNCTUATION_TOKEN_SORTS
  MORPHTAGGABLE_TOKEN_SORTS = WORD_TOKEN_SORTS
  DEPENDENCY_TOKEN_SORTS = WORD_TOKEN_SORTS + EMPTY_TOKEN_SORTS
end
