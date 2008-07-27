module SentenceFormattingHelper
  # Formats one or more sentences as a legible sequence of words. +value+ may
  # either be an array of +Sentence+ objects, a single +Sentence+ object or an
  # array of +Token+ objects.
  #
  # ==== Options
  # book_names:: If +true+, will prepend book names in front of the sentences.
  # The name will be contained within a +spann+ of class +book-name+.
  #
  # chapter_numbers:: If +true+, will prepend chapter numbers in front of
  # the sentence. The number will be contained in a +span+ of class
  # +chapter-number+.
  #
  # verse_numbers:: If +all+, will insert all verse numbers between the words
  # of the sentence. Each number will be contained within a +span+ of class
  # +verse-number+. If +noninitial+, will insert all verse numbers except
  # the first.
  #
  # sentence_numbers:: If +true+, will insert sentence numbers between the
  # words of the sentence. Each number will be contained within a +span+ of
  # class +sentence-number+.
  #
  # token_numbers:: If +true+, will insert token numbers after each token.
  # Each number will be contained within a +span+ of class +token_number+.
  #
  # focused_sentence:: If set to a sentence ID, will focus that sentence by
  # giving it an appropriate form of emphasis.
  #
  # tooltip:: If +morphtags+, will add a tool-tip for each word with its
  # POS and morphology.
  #
  # ignore_punctuation:: If +true+, will ignore any punctuation.
  #
  # ignore_presentation_forms:: If +true+, will preserve the token form of
  # of tokens with a presentation forms.
  #
  # length_limit:: If not +nil+, will limit the length of the formatted
  # sentence to the given number of words and append an ellipsis if the
  # sentence exceeds that limit. If a negative number is given, the
  # ellipis is prepended to the sentence.
  #
  # information_status:: If +true+, will put each token inside a span with a
  # class named as "info-status-#{token.info_status}"
  def format_sentence(value, options = {})
    x = nil

    if value.is_a?(Sentence)
      x = value.tokens
    elsif value.is_a?(Array)
      if value.empty?
        return []
      elsif value.first.is_a?(Sentence)
        x = value.map { |sentence| sentence.tokens }.flatten
      elsif value.first.is_a?(Token)
        x = value
      end
    end

    raise "Invalid value of type #{value.class}" if x.nil?

    format_tokens(x, x.first.language, options)
  end

  private

  UNICODE_HORIZONTAL_ELLIPSIS = Unicode::U2026

  FORMATTED_REFERENCE_CLASSES = {
    :book => 'book-name',
    :chapter => 'chapter-number',
    :verse => 'verse-number',
    :sentence => 'sentence-number',
    :token => 'token-number',
  }.freeze

  FormattedReference = Struct.new(:reference_type, :reference_value)

  class FormattedReference
    include ActionView::Helpers::TagHelper

    def spacing_before?
      reference_type != :token
    end

    def spacing_after?
      true
    end

    def selected?(options)
      case reference_type
      when :book
        options[:book_names]
      when :chapter
        options[:chapter_numbers]
      when :sentence
        options[:sentence_numbers]
      when :verse
        options[:verse_numbers] == :all || (options[:verse_numbers] == :noninitial and reference_value != 1)
      when :token
        options[:token_numbers]
      else
        raise ArgumentError, 'invalid reference type'
      end
    end

    def to_html(language, options)
      content_tag(:span, reference_value, :class => FORMATTED_REFERENCE_CLASSES[reference_type])
    end
  end

  FormattedToken = Struct.new(:token_type, :text, :nospacing, :link, :alt_text, :info_status)

  class FormattedToken
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper

    def spacing_before?
      nospacing.nil? or nospacing == :after
    end

    def spacing_after?
      nospacing.nil? or nospacing == :before
    end

    def selected?(options)
      if token_type == :punctuation
        !options[:ignore_punctuation]
      else
        true
      end
    end

    def to_html(language, options)
      case token_type
      when :lacuna_start, :lacuna_end
        content_tag(:span, UNICODE_HORIZONTAL_ELLIPSIS, :class => 'lacuna')
      when :punctuation
        text
      when :text
        if link
          klass = 'token'
          klass += ' ' + info_status if options[:information_status] && info_status
          link_to(LangString.new(text, language).to_h, link, :class => klass)
        else
          text
        end
      else
        raise "Invalid token type"
      end
    end
  end

  class EmptyFormattedToken < FormattedToken
    include Singleton

    def spacing_before?; false end
    def spacing_after?; false end
    def selected?(options); true end
    def to_html(language, options); '' end
  end

  def format_tokens(tokens, language, options)
    sequence = convert_to_presentation_sequence(tokens, options).select { |p| p.selected?(options) }

    sequence << EmptyFormattedToken.instance # add an extra non-rendering element so that each_cons doesn't miss the last token

    length_limit = options[:length_limit]

    if length_limit and sequence.length > length_limit
      if length_limit < 0
        UNICODE_HORIZONTAL_ELLIPSIS + join_sequence(sequence.last(-length_limit), language, options)
      else
        join_sequence(sequence.first(length_limit), language, options) + UNICODE_HORIZONTAL_ELLIPSIS
      end
    else
      join_sequence(sequence, language, options)
    end
  end

  def join_sequence(sequence, language, options)
    result = ''

    sequence.each_cons(2) do |x, y|
      result += x.to_html(language, options)
      result += "\n" if x.spacing_after? and y.spacing_before?
    end

    result
  end

  def check_reference_update(state, reference_type, reference_id, reference_value)
    if reference_id and state[reference_type] != reference_id
      state[reference_type] = reference_id
      FormattedReference.new(reference_type, reference_value)
    else
      nil
    end
  end

  def convert_to_presentation_sequence(tokens, options)
    state = {}
    t = []
    skip_tokens = 0

    tokens.reject(&:is_empty?).each do |token|
      if skip_tokens > 0
        skip_tokens -= 1
        next
      end

      t << check_reference_update(state, :book, token.sentence.book, token.sentence.book.title)
      t << check_reference_update(state, :chapter, token.sentence.chapter, token.sentence.chapter.to_i)
      t << check_reference_update(state, :sentence, token.sentence.sentence_number, token.sentence.sentence_number.to_i)
      t << check_reference_update(state, :verse, token.verse, token.verse.to_i)

      if token.presentation_form and not options[:ignore_presentation_forms]
        t << FormattedToken.new(token.sort, token.presentation_form, token.nospacing, annotation_path(token.sentence), nil, token.info_status)
        skip_tokens = token.presentation_span - 1
      elsif options[:tooltip] == :morphtags
        t << FormattedToken.new(token.sort, token.form, token.nospacing, annotation_path(token.sentence), readable_lemma_morphology(token), token.info_status)
      else
        t << FormattedToken.new(token.sort, token.form, token.nospacing, annotation_path(token.sentence), nil, token.info_status)
      end

      if token.presentation_span and token.presentation_span - 1 > 0
        t << FormattedReference.new(:token, "#{token.token_number}-#{token.token_number + token.presentation_span - 1}")
      else
        t << FormattedReference.new(:token, token.token_number)
      end
    end

    logger.info(t)
    t.compact
  end
end
