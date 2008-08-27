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
                  :token_number => token_number,
                  :notes => [] }
            (t/:notes/:note).each do |n|
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

  # FIXME: migrate to PROIEL::Source?
  
  # Merges two sources +a+ and +b+. It invokes the block
  # when it require normalisation and serialisation of a token
  # to a form suitable for comparisons. The two sources are
  # expected to be arrays of hashes; one hash per token. 
  # The merged source will be an array of hashes containing
  # all tokens from both +a+ and +b+, but for the tokens only
  # in +a+, a key +:deleted+ is added to the token hash, and
  # for the ones only in +b+, +added+ has been inserted.
  #
  # ==== Example
  #
  # merge_sources(a, b) do |source, token| 
  #   if source == :a
  #     token[:value].downcase
  #   else
  #     token[:value]
  #   end
  # end
  def PROIEL.merge_sources(a, b, options = {})
    # Compute difference
    a_normalised = a.collect { |t| yield(:a, t) }
    b_normalised = b.collect { |t| yield(:b, t) }

    a_normalised.extend(Diff::LCS)

    diffs = a_normalised.diff(b_normalised) 

    # Compute the result as a patched with b but with lazy deletions and 
    # flagged additions
    x, y = a.dup, b.dup
    xi, yi = 0, 0
    res = []

    diffs.each do |diff|
      diff.each do |change|
        case change.action
        when '+'
          while yi < change.position
            raise "Unexpected difference during addition" unless x.first[:token].downcase == y.first[:token].downcase

            res << x.shift
            y.shift
            xi += 1
            yi += 1
          end

          raise "Unexpected value #{y.first[:token]}, expected #{change.element}" unless y.first[:token].downcase == change.element.downcase

          # Perform the addition, and flag it
          res << y.shift
          res.last[:added] = true
          yi += 1

        when '-'
          while xi < change.position
            raise "Unexpected difference during removal" unless x.first[:token].downcase == y.first[:token].downcase

            res << x.shift
            y.shift
            xi += 1
            yi += 1
          end

          raise "Unexpected value #{x.first[:token]}, expected #{change.element}" unless x.first[:token].downcase == change.element.downcase

          # Lazy delete the token 
          res << x.shift
          res.last[:deleted] = true
          xi += 1
        else
          raise "Unknown change action #{change.action}"
        end
      end
    end

    # Verify the patching
    patch_test_tokens = res.reject {|t| t[:deleted] }.collect { |t| yield(:a, t) }
    raise "Patch failed" unless patch_test_tokens == b_normalised

    # Return result
    res
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

  # A PROIEL XML text writer.
  class TextWriter < Writer
    def initialize(file, text_id, language, metadata = {})
      metadata.keys.each do |k|
        unless [:title, :edition, :source, :editor, :url].include?(k.to_sym)
          raise ArgumentError, "Invalid metadata #{k.inspect}"
        end
      end

      @file = file
      @first_token = true # true if the next token is the first token in a sentence
      @seen_sentence_divider = false # true if write_token has seen a sentence divider which it
                                     # it still has not emitted

      @last_book = nil
      @last_chapter = nil
      @last_verse = nil

      @file.puts "<?xml version='1.0' encoding='utf-8'?>"
      @file.puts "<text id='#{text_id}' lang='#{language}'>"

      @file.puts "  <metadata>"
      [:title, :edition, :source, :editor, :url].each { |k| @file.puts "    <#{k}>#{metadata[k]}</#{k}>" if metadata[k] }
      @file.puts "  </metadata>"

      yield self

      close_all_elements
      @file.puts '</text>'
    end

    # Writes a token to the source. The function also takes care of tracking
    # book, chapter and verse identifiers and may do automatic reencoding and
    # normalisation of the token string. If +sentence_dividers+ is set,
    # will also insert sentence divisions whenever the required boundary
    # conditions are met. Returns the (reencoded) token form.
    def write_token(form, sort, book, chapter, verse, other_attributes = {}, reencoder = nil, sentence_dividers = nil, notes = nil)
      # Occasionally, we encounter texts in which punctuation and chapter divisions
      # don't add up. We therefore insert an extra sentence division whenever the
      # chapter number changes.
      next_sentence unless chapter.nil? or chapter.to_i == @last_chapter

      if @seen_sentence_divider
        # We've saved a note about a sentence divider having been encountered. This means
        # that we will have to start a new sentence now, UNLESS we immediately encounter
        # another sentence divider.
        unless sentence_dividers and sentence_dividers.include?(form)
          next_sentence
          @seen_sentence_divider = false
        end
      end

      track_references(book, chapter, verse) if book and chapter
      form = reencoder.call(form) if reencoder
      emit_word(other_attributes.merge({ :sort => sort, :form => form }), notes)

      if (sentence_dividers and sentence_dividers.include?(form)) or sort == :lacuna_start
        @seen_sentence_divider = true
      end
    end

    def tokenise_and_write_string(s, segmenter, book, chapter, verse, other_attributes = {}, reencoder = nil, sentence_dividers = nil)
      segmenter.segmenter(reencoder ? reencoder.call(s) : s) do |t|
        write_token(t[:form], t[:sort], book, chapter, verse, t.merge(other_attributes),
                    nil, sentence_dividers || [])
      end
    end

    alias :tokenize_and_write_string :tokenise_and_write_string

    def track_references(book, chapter, verse = nil)
      if book != @last_book
        @file.puts '    </sentence>' unless @first_token
        @file.puts '  </book>' if @last_book
        @file.puts "  <book name='#{book}'>"

        @first_token = true
      end

      @last_verse = verse.to_i if verse
      @last_chapter = chapter.to_i if chapter
      @last_book = book
    end

    private

    def escape_string(s)
      s.gsub(/</, '&lt;').gsub(/>/, '&gt;').gsub(/'/, '&quot;')
    end

    def emit_word(attrs = {}, notes = nil)
      @file.puts "    <sentence>" if @first_token
      @first_token = false

      xattrs = { :chapter => @last_chapter, :verse   => @last_verse }

      attrs.each_pair do |key, value|
        next if value.nil? or value == ''

        case key
        when :lemma, :presentation_form, :form
          xattrs[key] = Unicode.normalize_C(value) unless value.nil? or value == ''

        when :morphtag # morphtag
          value = MorphTag.new(value) unless value.is_a?(MorphTag)
          xattrs[key] = value.to_s unless value.empty?

        when :foreign_ids # key-value lists
          raise ArgumentError, "invalid value for token attribute 'foreign_ids'" unless value.is_a?(Hash)
          xattrs[key] = value.sort { |x, y| x.to_s <=> y.to_s }.collect { |k, v| v.nil? ? nil : "#{k}=#{v.gsub(',', '\\,')}" }.compact.join(',') unless value.empty?

        when :sort, :nospacing # symbols
          xattrs[key] = value.to_s.gsub(/_/, '-')

        when :contraction, :emendation, :abbreviation, :capitalisation # booleans
          case value
          when TrueClass, 'true'
            xattrs[key] = 'true'
          when FalseClass, 'false'
            xattrs[key] = 'false'
          else
            raise ArgumentError, "invalid value for token attribute '#{key}'"
          end

        when :id, :head, :slashes, :relation, :presentation_span # strings and integers
          xattrs[key] = value.to_s

        else
          raise ArgumentError, "invalid token attribute '#{key}'"
        end
      end

      formatted_attrs = xattrs.keys.collect(&:to_s).sort.collect { |k| "#{k.gsub(/_/, '-')}='#{escape_string(xattrs[k.to_sym].to_s)}'" }.join(' ')

      if notes
        @file.puts "      <token #{formatted_attrs}>"
        @file.puts "        <notes>"
        notes.each do |note|
          @file.puts "          <note origin='#{note[:origin]}'>#{escape_string(note[:text])}</note>"
        end
        @file.puts "        </notes>"
        @file.puts "      </token>"
      else
        @file.puts "      <token #{formatted_attrs}/>"
      end
    end

    public

    # Emits an array of tokens. Each token is a hash with the token
    # form as the value for the key :token, the reference as the values
    # of the keys :book, :chapter, and :verse. Any sentence number or
    # token number given will be ignored, other attributes as for
    # +emit_word+.
    #
    # ==== Options
    # track_sentence_numbers:: Do not ignore sentence numbers, but track
    # them and emit sentence divisions whenever they change.
    def emit_tokens(tokens, options = {})
      sentence_number = nil

      tokens.each do |token|
        token = token.dup
        token[:form] = token[:token]
        token.delete(:token)

        track_references(token[:book], token[:chapter], token[:verse])
        emit_word(token.except(:book, :chapter, :verse, :sentence_number, :token_number))

        if options[:track_sentence_numbers]
          sentence_number ||= token[:sentence_number]
          next_sentence if sentence_number != token[:sentence_number]
          sentence_number = token[:sentence_number]
        end
      end
    end

    def next_sentence
      @file.puts '    </sentence>' unless @first_token
      @first_token = true
    end

    private

    def close_all_elements
      @file.puts '    </sentence>' unless @first_token
      @file.puts '  </book>' if @last_book
    end
  end

  WORD_TOKEN_SORTS = [ :text ].freeze
  EMPTY_TOKEN_SORTS = [ :empty_dependency_token ].freeze
  PUNCTUATION_TOKEN_SORTS = [ :punctuation ].freeze
  NON_EMPTY_TOKEN_SORTS = WORD_TOKEN_SORTS + PUNCTUATION_TOKEN_SORTS
  MORPHTAGGABLE_TOKEN_SORTS = WORD_TOKEN_SORTS
  DEPENDENCY_TOKEN_SORTS = WORD_TOKEN_SORTS + EMPTY_TOKEN_SORTS

  # FIXME: where do these functions belong?

  # Returns true if token represents punctuation.
  def self.is_punctuation?(sort)
    PUNCTUATION_TOKEN_SORTS.include?(sort)
  end
end
