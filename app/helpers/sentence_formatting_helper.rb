module SentenceFormattingHelper
  # Formats one or more sentences as HTML using their content format.
  # +value+ may either be an array of +Sentence+ objects, a single
  # +Sentence+ object or an array of +Token+ objects.
  #
  # ==== Options
  #
  # <tt>:sentence_numbers</tt> -- If true, will insert sentence numbers in
  # the text between the words of the sentence.
  #
  # <tt>:token_numbers</tt> -- If true, will insert token numbers in the
  # text after each token.
  #
  # <tt>:citations</tt> -- If true, will insert citations whenever these
  # change.
  #
  # <tt>:sentence_breaks</tt> -- If true, will flag sentence breaks.
  #
  # <tt>:sentence_statuses</tt> -- If true, will show sentence statuses.
  #
  # <tt>:length_limit</tt> -- If not +nil+, will limit the length of the
  # formatted sentence to the given number of words and append an ellipsis
  # if the sentence exceeds that limit. If a negative number is given, the
  # ellipis is prepended to the sentence.
  #
  # <tt>:highlight</tt> -- A token or sentence object or an array of such
  # objects to highlight.
  #
  # <tt>:link_to</tt> -- If <tt>:tokens</tt>, will link to tokens. If
  # <tt>:sentences</tt>, will link to sentences.
  #
  # <tt>:single_line</tt> -- Ignore characters that indicate linefeeds and
  # paragraph breaks.
  #
  def format_sentence(value, options = {}, &block)
    options.reverse_merge! :highlight => []
    options[:highlight] = [options[:highlight]] if options[:highlight].is_a?(Token) or options[:highlight].is_a?(Sentence)

    x = nil

    value = value.all if value.is_a?(ActiveRecord::Relation)

    if value.is_a?(Sentence)
      x = value.tokens_with_deps_and_is
    elsif value.is_a?(Array)
      if value.empty?
        return ''
      elsif value.first.is_a?(Sentence)
        x = value.map { |sentence| sentence.tokens_with_deps_and_is }.flatten
      elsif value.first.is_a?(Token)
        x = value
      end
    end

    if x and x.length > 0
      markup = format_tokens(x, options, &block)
      "<div class='formatted-text' lang='#{x.first.language}'>#{markup}</div>".html_safe
    else
      ''
    end
  end

  private

  FormattedReference = Struct.new(:reference_type, :reference_value, :reference_url)

  class FormattedReference
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper

    def spacing_before?
      reference_type != :token_number
    end

    def spacing_after?
      true
    end

    def selected?(options)
      case reference_type
      when :sentence_break
        options[:sentence_breaks]
      when :sentence_status
        options[:sentence_statuses]
      when :sentence_number
        options[:sentence_numbers]
      when :token_number
        options[:token_numbers]
      when :citation
        options[:citations]
      else
        raise ArgumentError, 'invalid reference type'
      end
    end

    def to_html(options)
      case reference_type
      when :sentence_status
        link_to '', reference_url, :class => reference_value
      else
        if reference_value.to_s.empty?
          ''
        elsif reference_url
          link_to reference_value.to_s, reference_url, :class => reference_type.to_s.dasherize, :lang => 'en'
        else
          content_tag :span, reference_value.to_s, :class => reference_type.to_s.dasherize, :lang => 'en'
        end
      end
    end
  end

  FormattedToken = Struct.new(:token, :extra_attributes, :object_url)

  class FormattedToken
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ApplicationHelper

    def spacing_before?
      true
    end

    def spacing_after?
      true
    end

    def selected?(options)
      true
    end

    def to_html(options)
      presentation_attributes = {}
      form_attributes = presentation_attributes.merge(extra_attributes || {})
      form_attributes[:class] ||= ''
      form_attributes[:class] += ' token'

      if options[:highlight].include?(token) or options[:highlight].include?(token.sentence)
        presentation_attributes[:class] = 'highlight'
        form_attributes[:class] += ' highlight'
      end

      form_attributes[:class].strip!

      before = token.all_presentation_before
      after = token.all_presentation_after

      s = ''
      s += content_tag :span, TokenText.token_form_as_html(before, single_line: options[:single_line]).html_safe, presentation_attributes unless before.empty?

      form = TokenText.token_form_as_html(token.form_or_pro, single_line: options[:single_line]).html_safe

      case options[:link_to]
      when :tokens, :sentences
        s += link_to form, object_url, form_attributes
      else
        s += content_tag :span, form, form_attributes
      end

      s += content_tag :span, TokenText.token_form_as_html(after, single_line: options[:single_line]).html_safe, presentation_attributes unless after.empty?
      s.squish
    end
  end

  class EmptyFormattedToken < FormattedToken
    include Singleton

    def spacing_before?; false end
    def spacing_after?; false end
    def selected?(options); true end
    def to_html(options); '' end
  end

  def format_tokens(tokens, options, &block)
    sequence = convert_to_presentation_sequence(tokens, options, &block).select { |p| p.selected?(options) }

    sequence << EmptyFormattedToken.instance # add an extra non-rendering element so that each_cons doesn't miss the last token

    length_limit = options[:length_limit]

    if length_limit and sequence.length > length_limit.abs
      if length_limit < 0
        "\u{2026}" + join_sequence(sequence.last(-length_limit), options)
      else
        join_sequence(sequence.first(length_limit), options) + "\u{2026}"
      end
    else
      join_sequence(sequence, options)
    end
  end

  def join_sequence(sequence, options)
    sequence.map { |x| x.to_html(options) }.join
  end

  def check_reference_update(state, reference_type, reference_id, reference_value, reference_object = nil)
    if reference_id and state[reference_type] != reference_id
      state[reference_type] = reference_id
      FormattedReference.new(reference_type, reference_value, reference_object ? url_for(reference_object) : reference_object)
    else
      nil
    end
  end

  def convert_to_presentation_sequence(tokens, options, &block)
    state = { }
    t = []

    tokens.reject { |token| options[:information_status] ? (token.is_empty? and token.empty_token_sort != 'P' ) : token.is_empty? }.each_with_index do |token, i|
      t << check_reference_update(state, :sentence_break, token.sentence.id, i.zero? ? '' : '|')

      # Skip citation update for empty tokens, which will be found in the form
      # of empty PRO tokens when formatting information structure, as these are
      # unlikely to have a valid citation_part value.
      t << check_reference_update(state, :citation, token.citation_part, token.citation_part, url_for(token.sentence)) unless token.is_empty?
      t << check_reference_update(state, :sentence_status, token.sentence.id, token.sentence.status, url_for(token.sentence))
      t << check_reference_update(state, :sentence_number, token.sentence.sentence_number, token.sentence.sentence_number.to_i, url_for(token.sentence))

      extra_attributes = block ? block.call(token) : nil

      case options[:link_to]
      when :tokens
        t << FormattedToken.new(token, extra_attributes, url_for(token))
      when :sentences
        t << FormattedToken.new(token, extra_attributes, url_for(token.sentence))
      else
        t << FormattedToken.new(token, extra_attributes)
      end
      t << FormattedReference.new(:token_number, token.token_number, url_for(token))
    end

    t.compact
  end
end
