require 'proiel'

module ApplicationHelper
  # Inserts javascript files in the layout.
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  # Inserts stylesheets in the layout.
  def stylesheet(*files)
    content_for(:head) { stylesheet_link_tag(*files) }
  end

  # Returns an HTML block with formatted error messages.
  def error_messages(msg, *params)
    options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
    objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    count   = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
      header_message = "Error #{msg}:"
      error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }
      message(:error, "Error #{msg}:", content_tag(:ul, error_messages))  
    else
      ''
    end
  end

  def message(level, header, body = '')
    content_tag(:div, content_tag(:b, header) + body, :id => level)
  end

  # Generates a lemma and morphology description for a token.
  def readable_lemma_morphology(token, options = {})
    if token.lemma
      popup = []
      popup << "#{token.lemma.lemma}" if token.lemma
      popup << "(#{token.morph.descriptions([], false).join(', ')})" if token.morphtag
      popup.join(' ')
    else
      ''
    end
  end

  # Generayes a link to a lemma.
  def link_to_lemma(lemma)
    link_to(lemma.variant ? "#{lemma.lemma}##{lemma.variant}" : lemma.lemma, lemma)
  end

  # Returns the contents of +value+ unless +value+ is +nil+, in which case it
  # returns the HTML entity for non-breakable space.
  def make_nonblank(value)
    value.nil? || value == '' ? '&nbsp;' : value
  end

  def _select_tag(name, value, option_tags, options = {}) #:nodoc:
    if options[:include_blank]
      options.delete(:include_blank)
      if value.nil? or value == ''
        select_tag name, "<option value='' selected='selected'></options>" + option_tags, options
      else
        select_tag name, "<option value=''></options>" + option_tags, options
      end
    else
      select_tag name, option_tags, options
    end
  end

  # Returns a select tag for the morphtag field +field+.
  def morphtag_select_tag(name, field, value = nil, options = {})
    value = value.to_sym unless value.nil? or value == ''
    option_tags = PROIEL::MORPHOLOGY[field].sort { |a, b| a.to_s <=> b.to_s }.collect do |code, values|
      if code == value
        "<option value='#{code}' selected='selected'>#{values.summary.capitalize}</option>"
      else
        "<option value='#{code}'>#{values.summary.capitalize}</option>"
      end
    end.join

    _select_tag name, value, option_tags, options
  end

  # Returns a select tag for languages.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def language_select_tag(name, value = nil, options = {})
    value = value.to_sym unless value.nil? or value == '' 
    option_tags = PROIEL::LANGUAGES.collect do |code, values| 
      if code == value
        "<option value='#{code}' selected='selected'>#{values.summary}</option>"
      else
        "<option value='#{code}'>#{values.summary}</option>"
      end
    end.join

    _select_tag name, value, option_tags, options
  end

  # Returns a select tag for relations. 
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def relation_select_tag(name, value = nil, options = {})
    relations = PROIEL::RELATIONS.values.collect { |r| r.code.to_s }

    option_tags = relations.collect do |r| 
      if r == value
        "<option value='#{r}' selected='selected'>#{r.upcase}</option>"
      else
        "<option value='#{r}'>#{r.upcase}</option>"
      end
    end.join

    _select_tag name, value, option_tags, options
  end

  # Returns a select tag for completion rates. 
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def completion_select_tag(name, value = nil, options = {})
    value = value.to_sym unless value.nil? or value == ''
    vals = {
      :none => 'Not annotated', 
      :annotated => 'Annotated',
      :reviewed => 'Reviewed'
    }

    option_tags = vals.collect do |code, meaning| 
      if code == value
        "<option value='#{code}' selected='selected'>#{meaning}</option>"
      else
        "<option value='#{code}'>#{meaning}</option>"
      end
    end.join

    _select_tag name, value, option_tags, options
  end

  def _select_tag_db(name, model, value_field, value, options) #:nodoc:
    option_tags = options_from_collection_for_select(model.find(:all), :id, value_field, value.to_i)
    _select_tag name, value, option_tags, options
  end

  # Returns a select tag for sources.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def source_select_tag(name, value, options = {})
    _select_tag_db(name, Source, :presentation_form, value, options)
  end

  # Returns a select tag for books.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def book_select_tag(name, value, options = {})
    _select_tag_db(name, Book, :presentation_form, value, options)
  end

  # Returns a select tag for chapters. 
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def chapter_select_tag(name, value, options = {})
    option_tags = options_from_collection_for_select(Sentence.find(:all, :group => 'chapter'), :chapter, :chapter, value.to_i)
    _select_tag name, value, option_tags, options
  end

  # Returns a select tag for users.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def user_select_tag(name, value, options = {})
    _select_tag_db(name, User, :login, value, options)
  end

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
  # ignore_clitc_reordering:: If +true+, will not reorder enclitics.
  #
  # ignore_fusing:: If +true+, will not fuse bound morphemes with their
  # hosts.
  #
  # no_spacing:: Do not insert spaces in the final result, but rather return
  # the result as an array of processed items.
  def format_sentence(value, options = {})
    # Determine what we are dealing with
    return [] if value.is_a?(Array) and value.empty?

    if value.is_a?(Sentence) || (value.is_a?(Array) and value.first.is_a?(Token))
      # Value is a single sentence or an array of tokens. In either case
      # we pretend it's a list of sentences.
      sentences = [value]
    else
      # This should then be an array of actual sentences.
      raise "Invalid value of type #{value.class}" unless value.is_a?(Array) and value.first.is_a?(Sentence)
      sentences = value
    end

    # Set up state information
    t = [] 

    n_book = nil
    n_chapter = nil
    n_verse = nil
    n_sentence = nil

    clitic = nil
    dangling_punctuation = nil

    # Do the dirty deed
    sentences.each do |sentence|
      if sentence.is_a?(Array) and sentence.first.is_a?(Token)
        tokens = sentence
      else
        tokens = sentence.tokens
      end

      i_tokens = tokens + [nil]  # Append an extra nil token so that each_cons works to our advantage

      i_tokens.each_cons(2) do |token, next_token|
        next if token.empty?

        # Check if the next token is bound and we should fuse it
        next if next_token and (next_token.sort == :fused_morpheme and not options[:ignore_fusing])

        # Add book name
        if options[:book_names] and token.sentence.book and n_book != token.sentence.book
          t << content_tag(:span, token.sentence.book.title, :class => 'book-name')
          n_book = token.sentence.book
        end

        # Add chapter number
        if options[:chapter_numbers] and token.sentence.chapter and n_chapter != token.sentence.chapter.to_i
          t << content_tag(:span, token.sentence.chapter, :class => 'chapter-number')
          n_chapter = token.sentence.chapter.to_i
        end

        # Add sentence number
        if options[:sentence_numbers] and n_sentence != token.sentence.sentence_number.to_i
          t << content_tag(:span, token.sentence.sentence_number, :class => 'sentence-number')
          n_sentence = token.sentence.sentence_number.to_i
        end

        # Add verse number
        if options[:verse_numbers] and token.verse and n_verse != token.verse.to_i 
          if options[:verse_numbers] == :all || (options[:verse_numbers] == :noninitial and token.verse != 1)
            t << content_tag(:span, token.verse, :class => 'verse-number')
          end
          n_verse = token.verse.to_i
        end

        # Determine the appropriate CSS classes for the tokens to be emitted
        token_class = (token.sentence_id == options[:focused_sentence]) ? 'token focused' : 'token'

        # Determine how to actually treat the presentation of the token
        present_as_sort = token.sort
        present_as_sort = :word if options[:ignore_fusing] and token.sort == :fused_morpheme
        present_as_sort = :word if options[:ignore_clitic_ordering] and token.sort = :enclitic

        case present_as_sort
        when :nonspacing_punctuation, :right_bracketing_punctuation
          if t.empty?
            # We do actually permit "sentences" to start with nonspacing punctuation
            # in the case of concordances where the search word is split off and
            # treated separately
            t << token.form
          else
            t.last << token.form
          end

        when :left_bracketing_punctuation
          dangling_punctuation = token

        when :spacing_punctuation
          t << token.form

        when :enclitic
          clitic = token

        when :fused_morpheme
          s = link_to(token.composed_form, annotation_path(token.sentence), :class => token_class + ' bad')
          s << content_tag(:span, "#{token.token_number - 1}-#{token.token_number}", 
                           :class => 'token-number') if options[:token_numbers]
          t << s

        when :word
          s = ''

          if dangling_punctuation
            s << dangling_punctuation.form
            dangling_punctuation = nil
          end

          if options[:tooltip] == :morphtags
            s << link_to(token.form, annotation_path(token.sentence), :class => token_class, :title => readable_lemma_morphology(token))
          else
            s << link_to(token.form, annotation_path(token.sentence), :class => token_class)
          end
          s << content_tag(:span, token.token_number, :class => 'token-number') if options[:token_numbers]

          if clitic
            if options[:tooltip] == :morphtags
              s << link_to(clitic.form, annotation_path(clitic.sentence), :class => token_class, :title => readable_lemma_morphology(clitic))
            else
              s << link_to(clitic.form, annotation_path(clitic.sentence), :class => token_class)
            end
            s << content_tag(:span, clitic.token_number, :class => 'token-number') if options[:token_numbers]
            clitic = nil
          end
          t << s
        end
      end
    end

    options[:no_spacing] ? t : t.join(' ')
  end

  # Makes an information box intended for display of meta-data and navigational
  # aids.
  def make_information_box(entries, nav_actions = nil)
    entries = entries.collect { |e| "<dt>#{e[0]}:</dt><dd>#{e[1]}</dd>" }
    content = ''
    content += content_tag(:dl, entries)
    content += content_tag(:p, nav_actions.join) if nav_actions 
    content_tag(:div, content, :class => :roundedbox)
  end

  # Returns a radio button with a function as onclick handler.
  def radio_button_to_function(name, value, checked, *args, &block)
    html_options = args.extract_options!
    function = args[0] || ''

    html_options.symbolize_keys!
    function = update_page(&block) if block_given?
    tag(:input, html_options.merge({ 
        :type => "radio", :name => name, :value => value, :checked => checked,
        :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + "#{function};" 
    }))
  end

  # Generates a search form.
  def search_form_tag(submit_path, &block)
    html_options = html_options_for_form(submit_path, :method => 'get', :class => 'search')
    content = capture(&block)
    concat(form_tag_html(html_options), block.binding)
    concat(content, block.binding)
    concat(submit_tag('Search', :name => nil) + '</form>', block.binding)
  end

  # Generates a fancy tool-tip.
  def tool_tip(tool, tip)
    %Q{<span class="tool">#{tool}<span class="tip">#{tip}</span></span>}
  end

  # Generates a human readable representation of a token sort.
  def readable_token_sort(sort)
    sort.to_s.humanize
  end

  # Generates human readable POS information for a morphtag.
  def readable_pos(morphtag)
    make_nonblank(morphtag ? morphtag.descriptions([:major, :minor]).join(', ').capitalize : nil)
  end

  # Generates human readable morphology information for a morphtag. 
  def readable_morphology(morphtag)
    make_nonblank(morphtag ? morphtag.descriptions([:major, :minor], false).join(', ').capitalize : nil)
  end

  # Generates a human readable representation of a language code.
  #
  # ==== Example
  #  c = readable_language(:la)
  #  c # => "Latin"
  #
  def readable_language(code)
    make_nonblank(PROIEL::LANGUAGES[code].summary)
  end

  # Generates a human readable representation of a completion rate for a sentence.
  def readable_completion(sentence, options = {})
    if sentence.is_reviewed?
      s = "Reviewed"
    elsif sentence.is_annotated?
      s = "Annotated"
    else
      s = "Not annotated"
    end

    if options[:checkmark]
      if options[:checkmark] == :only
        c = '&nbsp;'
      else
        c = s
      end

      if sentence.is_reviewed?
        content_tag(:span, c, :class => 'reviewed')
      elsif sentence.is_annotated?
        content_tag(:span, c, :class => 'annotated')
      else
        content_tag(:span, c, :class => 'unannotated')
      end
    else
      s
    end
  end

  # Generates a human readble representation of a relation code.
  def readable_relation(code)
    return "<span class='relation bad'>#{code}</span>" unless code and PROIEL::RELATIONS.has_key?(code.to_sym)

    summary = PROIEL::RELATIONS[code].summary

    if summary
      "<span class='relation'><abbr title='#{summary.capitalize}'>#{code}</abbr></span>"
    else
      "<span class='relation'>#{code}</span>"
    end
  end

  # Generates a human readable representation of a dependency.
  def readable_dependency(relation, head)
    '(' + readable_relation(relation) + (head ? ", #{head}" : '') + ')'
  end

  # Generates a human readable location reference.
  def readable_reference(reference)
    "#{reference} (#{reference.classical_reference})"
  end

  # Generates a human readable 'yes'/'no' representation of a boolean value.
  def readable_boolean(x)
    x ? 'Yes' : 'No'
  end

  # Generates links to external Bible sites for a reference.
  def external_text_links(reference)
    [ link_to('Biblos', reference.external_url(:biblos), :class => 'external'),
      link_to('bibelen.no', reference.external_url(:bibelen_no), :class => 'external'), ].join('&nbsp;');
  end

  def wizard_options(ignore, options)
    s = ''
    if options
      c = controller.controller_name
      s << button_to('Edit', :controller => :wizard, :action => "modify_#{c}", :wizard => options, :annotation_id => params[:annotation_id]) if options[:edit] 
      s << button_to('Verify', :controller => :wizard, :action => "verify_#{c}", :wizard => options, :annotation_id => params[:annotation_id]) if options[:verify] 
      s << button_to('Skip', :controller => :wizard, :action => "skip_#{c}", :wizard => options, :annotation_id => params[:annotation_id]) if options[:skip] 
    elsif ignore
      s << button_to('Edit', { :action => 'edit', :method => 'get' }, :method => 'get' )
    end
    s
  end

  # Generates a rounded box with a description list inside.
  def roundedbox(&block)
    content = capture(&block)
    concat("<div class='roundedbox'><dl>", block.binding)
    concat(content, block.binding)
    concat("</dl></div>", block.binding)
  end

  # Generates a title header and a set of associated links directly
  # next to the header.
  def layer(id, options = {}, &block)
    title = options[:title]
    title ||= id.humanize
    actions = options[:actions]
    actions = "(#{actions.join(' | ')})" if actions

    content = capture(&block)
    concat("<div id='#{id}' class='layer'><h1 class='layer-title'>#{title}</h1> <span class='layer-actions'>#{actions}</span><div class='layer-content'>", block.binding)
    concat(content, block.binding)
    concat("</div></div>", block.binding)
  end

  # Generates a title header and a set of associated links directly
  # next to the header if the condition +condition+ is +true+. Otherwise
  # takes no action. The remainin arguments are the same as for
  # +layer+.
  def layer_if(condition, *args, &block)
    condition ? layer(*args, &block) : ''
  end

  # Generates a title header and a set of associated links directly
  # next to the header unless the condition +condition+ is +true+. Otherwise
  # takes no action. The remainin arguments are the same as for
  # +layer+.
  def layer_unless(condition, *args, &block)
    layer_if(!condition, *args, &block)
  end

  def format_ratio(part, total)
    number_with_precision(part.to_i * 100 / total.to_f, 1) + '%'
  end

  # Creates hidden 'Previous' and 'Next' links for per-sentence annotation displays
  # with standard access keys P and N.
  def annotation_navigation_links(sentence, url_function)
    link_to_if(sentence.has_previous_sentence?, 'Previous', self.send(url_function, sentence.previous_sentence),
               :accesskey => 'p') + '&nbsp;' +
    link_to_if(sentence.has_next_sentence?, 'Next', self.send(url_function, sentence.next_sentence),
               :accesskey => 'n')
  end

  # Generates a link if the condition +condition+ is +true+, otherwise
  # takes no action. The remaining arguments are the same as those 
  # for +link_to+.
  def show_link_to_if(condition, *args)
    condition ? link_to(*args) : ''
  end

  # Generates a link if the current user has the role +role+, otherwise
  # takes no action. The remaining arguments are the same as those for 
  # +link_to+.
  def show_link_to_for_role(role, *args)
    show_link_to_if(current_user.has_role?(role), *args)
  end
end
