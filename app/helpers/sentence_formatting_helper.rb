require 'ucodes'

module SentenceFormattingHelper
  # Formats an array of sentences as HTML using their presentation
  # format.
  #
  # ==== Options
  #
  # <tt>:section_numbers</tt> -- If true, will display section
  # numbers.
  #
  # <tt>:sentence_numbers</tt> -- If true, will display sentence
  # numbers.
  #
  # <tt>:highlight</tt> -- If set to an array of sentences, will
  # highlight those sentences.
  #
  # <tt>:ignore_links</tt> -- If true, will not produce links to other
  # resources, e.g. to annotation views for sentences, in the
  # sentence.
  def format_presentation_text(sentences, options = {})
    options.reverse_merge! :section_numbers => false,
      :sentence_numbers => false, :highlight => []

    current_sentence_number = nil

    markup = sentences.map do |sentence|
      m = ''
      if options[:sentence_numbers] and sentence.sentence_number and current_sentence_number != sentence.sentence_number
        current_sentence_number == sentence.sentence_number
        m = "<section type='sentence-number' n='#{sentence.sentence_number}'/>&nbsp;"
      end

      s = sentence.presentation_as_html(options)
      s = '<span class="highlight">' + s + '</span>' if options[:highlight].include?(sentence)
      s = link_to(s, sentence) unless options[:ignore_links]
      m + s
    end.join(' ')
  end

  # Formats one or more sentences as HTML using their content format.
  # +value+ may either be an array of +Sentence+ objects, a single
  # +Sentence+ object or an array of +Token+ objects.
  #
  # ==== Options
  #
  # <tt>:sentence_numbers</tt> -- If true, will insert sentence
  # numbers between the words of the sentence. Each number will be
  # contained within a +span+ of class +sentence-number+.
  #
  # <tt>:token_numbers</tt> -- If true, will insert token numbers
  # after each token. Each number will be contained within a +span+ of
  # class +token_number+.
  #
  # <tt>:length_limit</tt> -- If not +nil+, will limit the length of
  # the formatted sentence to the given number of words and append an
  # ellipsis if the sentence exceeds that limit. If a negative number
  # is given, the ellipis is prepended to the sentence.
  #
  # <tt>:highlight</tt> -- If set to an array of tokens, will
  # highlight those tokens.
  #
  # <tt>:information_status</tt> -- If true, will put each token
  # inside a span with a class named as
  # "info-status-#{token.info_status}"
  #
  # <tt>:ignore_links</tt> -- If true, will not produce links to other
  # resources, e.g. to annotation views for sentences, in the
  # sentence.
  def format_sentence(value, options = {})
    options.reverse_merge! :highlight => []

    x = nil

    if value.is_a?(Sentence)
      x = value.tokens_with_dependents_and_info_structure.with_prodrops_in_place
    elsif value.is_a?(Array)
      if value.empty?
        return []
      elsif value.first.is_a?(Sentence)
        x = value.map { |sentence| sentence.tokens_with_dependents_and_info_structure.with_prodrops_in_place }.flatten
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
      when :sentence
        options[:sentence_numbers]
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

  FormattedToken = Struct.new(:text, :link, :extra_css, :token)

  class FormattedToken
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper

    def spacing_before?
      true
    end

    def spacing_after?
      true
    end

    def selected?(options)
      true
    end

    def to_html(language, options)
      css = extra_css || []

      if link
        link_to(LangString.new(text, language).to_h, link, :class => (css << 'token') * ' ')
      elsif options[:information_status]
        if options[:highlight].include?(token)
          css << info_status_css_class
          css << 'ant-' + token.antecedent.id.to_s if token.antecedent
          css << 'con-' + token.contrast_group if token.contrast_group
          css << 'verb' if token.verb?
        end
        css << 'con-' + token.contrast_group if token.contrast_group
        LangString.new(text, language, :id => 'token-' + token.id.to_s, :css => css * ' ').to_h
      else
        content_tag(:span, LangString.new(text, language).to_h, :class => css * ' ')
      end
    end

    private

    def info_status_css_class
      @info_status_css_class ||= if token.info_status && token.info_status != :info_unannotatable
                                   'info-annotatable ' + token.info_status.to_s.gsub('_', '-')
                                 elsif token.is_annotatable?
                                   'info-annotatable no-info-status'
                                 else
                                   'info-unannotatable'
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

    tokens.reject { |token| options[:information_status] ? (token.is_empty? and token.empty_token_sort != 'P' ) : token.is_empty? }.each do |token|
      t << check_reference_update(state, :sentence, token.sentence.sentence_number, token.sentence.sentence_number.to_i)

      extra_css = []
      extra_css << :highlight if options[:highlight].include?(token)

      t << FormattedToken.new(token.form, (options[:ignore_links] or options[:information_status]) ? nil : token.sentence, extra_css, token)
      t << FormattedReference.new(:token, token.token_number)
    end

    t.compact
  end
end
