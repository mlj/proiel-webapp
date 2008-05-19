#!/usr/bin/env ruby
#
# source.rb - PROIEL source file manipulation functions
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'simplepullparser'
require 'unicode'

module PROIEL
  # FIXME: moronic Rails (documentation). This clashes with ::Source
  # in the webapp and causes all sorts of weird problems. Why?
  class XSource
    def initialize(filename)
      @metadata = { :filename => filename } 
      @books = []

      parser = SimplePullParser.new(File.open(filename))
      parser.parse do |element_path, attributes, text|
        case element_path.join('/')
        when 'text'
          @metadata[:id] = attributes[:id]
          @metadata[:language] = attributes[:lang].to_sym
        when 'text/metadata'
          # Ignore
        when 'text/metadata/title'
          @metadata[:title] = text
        when 'text/metadata/edition'
          @metadata[:text] = text
        when 'text/metadata/source'
          @metadata[:source] = text
        when 'text/metadata/editor'
          @metadata[:editor] = text
        when 'text/metadata/url'
          @metadata[:url] = text
        when 'text/book'
          @books << attributes[:name]
        end
      end
    end

    # Returns the list of books defined in the source. The list is
    # returned as an array of book codes.
    attr_reader :books

    # Returns the meta-data for the source. The meta-data is returned
    # as a hash with keys corresponding to elements in the meta-data
    # header, and including the source identifier, language tag
    # and filename.
    attr_reader :metadata
  end

  # FIXME/Deprecated: migrate to PROIEL::Source
  def PROIEL.read_source2(file, options = {})
    metadata = {} 

    book = nil
    sentence_number = nil
    token_number = nil

    read_tokens = false

    tokens = []

    parser = SimplePullParser.new(File.open(file))
    parser.parse do |element_path, attributes, text|
      case element_path.join('/')
      when 'text'
        metadata[:id] = attributes[:id]
        metadata[:language] = attributes[:lang].to_sym
      when 'text/metadata'
        # Ignore
      when 'text/metadata/title'
        metadata[:title] = text
      when 'text/metadata/edition'
        metadata[:text] = text
      when 'text/metadata/source'
        metadata[:source] = text
      when 'text/metadata/editor'
        metadata[:editor] = text
      when 'text/metadata/url'
        metadata[:url] = text
      when 'text/book'
        sentence_number = 0
        if options[:filters] and options[:filters][:book]
          # Only commence reading if this is the book
          # that we're looking for
          if attributes[:name] == options[:filters][:book] 
            read_tokens = true
          else
            # Not our book; if tokens has already been set, we've
            # evidently already read out book so we might as well
            # break off.
            break if read_tokens
          end
        else
          # Commence reading.
          read_tokens = true
        end
        book = attributes[:name]
      when 'text/book/sentence'
        sentence_number += 1
        token_number = 0
      when 'text/book/sentence/token'
        token_number += 1
        if read_tokens
          a = attributes || {}
          a.merge!({ :book => book, :sentence_number => sentence_number, :token_number => token_number })
          a[:composed_form] = a[:"composed-form"] if a[:"composed-form"] #FIXME 
          a[:sort] = a[:sort].gsub(/-/, '_').to_sym
          tokens.push [ text, a ]
        end
      end
    end

    [metadata, tokens]
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

  # A PROIEL source writer.
  class Writer
    def initialize(filename, text_id, lang, metadata, &block)
      @text_id = text_id
      @lang = lang
      @first_word = true

      @last_book = nil
      @last_chapter = nil
      @last_verse = nil

      File.open(filename, 'w') do |@f|
        # Output prologue
        puts "<?xml version='1.0' encoding='utf-8'?>"
        puts "<text id='#{@text_id}' lang='#{@lang}'>"

        puts "  <metadata>"
        [:title, :edition, :source, :editor, :url].each do |e|
          puts "    <#{e}>#{metadata[e]}</#{e}>" if metadata[e]
        end
        puts "  </metadata>"

        instance_eval(&block)

        # Ensure that all div elements are closed
        close_all_elements

        # Output epilogue
        puts '</text>'
      end
    end

    def segment_sentence(segmenter, sentence_dividers, text, book, chapter, verse = nil,
                         reencoder = nil)
      # Occasionally, we encounter texts in which punctuation and chapter divisions
      # don't add up. We therefore insert an extra sentence division whenever the
      # chapter number changes.
      next_sentence unless chapter.nil? or chapter.to_i == @last_chapter

      track_references(book, chapter, verse) 

      segmenter.segmenter(reencoder ? reencoder.call(text) : text) do |t|
        if t[:sort] == :nonspacing_punctuation
          emit_word(t[:form], t.slice(:sort)) 
        else
          emit_word(t[:form], t.slice(:sort, :composed_form)) 
        end 

        if t[:sort] == :nonspacing_punctuation
          next_sentence if sentence_dividers.include?(t[:form])
        end
      end
    end

    def track_references(book, chapter, verse = nil)
      if book != @last_book
        puts '    </sentence>' unless @first_word
        puts '  </book>' if @last_book
        puts "  <book name='#{book}'>"

        @first_word = true
      end

      @last_verse = verse.to_i if verse
      @last_chapter = chapter.to_i if chapter
      @last_book = book
    end

    def emit_word(form, attrs = {})
      puts "    <sentence>" if @first_word
      @first_word = false
      xattrs = attrs.dup
      xattrs[:chapter] = @last_chapter
      xattrs[:verse] = @last_verse
      xattrs[:lemma] = Unicode.normalize_C(xattrs[:lemma]) if xattrs[:lemma]
      formatted_attrs = xattrs.keys.collect { |s| s.to_s }.sort.collect { |k| " #{k.gsub(/_/, '-')}='#{xattrs[k.to_sym].to_s.gsub(/_/, '-')}'" }
      puts "      <token#{formatted_attrs}>#{form ? Unicode.normalize_C(form) : '' }</token>"
    end

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
        track_references(token[:book], token[:chapter], token[:verse])
        emit_word(token[:token], token.except(:token, :book, :chapter, :verse, 
                                              :sentence_number, :token_number))

        if options[:track_sentence_numbers]
          sentence_number ||= token[:sentence_number]
          next_sentence if sentence_number != token[:sentence_number]
          sentence_number = token[:sentence_number]
        end
      end
    end

    def next_sentence
      puts '    </sentence>' unless @first_word

      @first_word = true
    end

    private

    def close_all_elements
      puts '    </sentence>' unless @first_word
      puts '  </book>' if @last_book
    end

    def puts(s)
      @f.puts s
    end
  end

  WORD_TOKEN_SORTS =
    [ :word, :fused_morpheme, :enclitic ].freeze
  EMPTY_TOKEN_SORTS =
    [ :empty ].freeze
  NON_BRACKETING_PUNCTUATION_TOKEN_SORTS =
    [ :nonspacing_punctuation, :spacing_punctuation ].freeze
  BRACKETING_PUNCTUATION_TOKEN_SORTS =
    [ :left_bracketing_punctuation, :right_bracketing_punctuation ].freeze

  PUNCTUATION_TOKEN_SORTS =
    NON_BRACKETING_PUNCTUATION_TOKEN_SORTS + BRACKETING_PUNCTUATION_TOKEN_SORTS
  NON_EMPTY_TOKEN_SORTS =
    WORD_TOKEN_SORTS + PUNCTUATION_TOKEN_SORTS

  MORPHTAGGABLE_TOKEN_SORTS = WORD_TOKEN_SORTS
  DEPENDENCY_TOKEN_SORTS = WORD_TOKEN_SORTS + EMPTY_TOKEN_SORTS

  # FIXME: where do these functions belong?

  # Returns true if token sort represents a non-bracketing type of punctuation.
  def self.is_non_bracketing_punctuation?(sort)
    NON_BRACKETING_PUNCTUATION_TOKEN_SORTS.include?(sort)
  end

  # Returns true if token represents a bracketing type of punctuation.
  def self.is_bracketing_punctuation?(sort)
    BRACKETING_PUNCTUATION_TOKEN_SORTS.include?(sort)
  end

  # Returns true if token represents punctuation.
  def self.is_punctuation?(sort)
    PUNCTUATION_TOKEN_SORTS.include?(sort)
  end
end
