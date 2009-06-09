module ApplicationHelper
  # Inserts javascript files in the layout.
  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  # Inserts stylesheets in the layout.
  def stylesheet(*files)
    content_for(:head) { stylesheet_link_tag(*files) }
  end

  def message(level, header, body = '')
    content_tag(:div, content_tag(:b, header) + body, :id => level)
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

  def _select_tag_db(name, model, value_field, value, options) #:nodoc:
    option_tags = options_from_collection_for_select(model.find(:all), :id, value_field, value.to_i)
    _select_tag name, value, option_tags, options
  end

  # Returns a select tag for sources.
  #
  # ==== Options
  # +:include_blank+:: If +true+, includes an empty value first.
  def source_select_tag(name, value, options = {})
    _select_tag_db(name, Source, :citation, value, options)
  end

  # Enters Markaby "mode"; actually just a wrapper for the-semi ugly Markaby + helper hack.
  # Borrowed from http://railscasts.com/episodes/69.
  def markaby(&block)
    Markaby::Builder.new({}, self, &block)
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

  # Generates a human readable representation of a completion rate for a sentence.
  def readable_completion(sentence, options = {})
    if sentence.is_reviewed?
      show_completion_rate(:reviewed, options)
    elsif sentence.is_annotated?
      show_completion_rate(:annotated, options)
    else
      show_completion_rate(:unannotated, options)
    end
  end

  # Generates a human readable representation of a completion rate.
  def show_completion_rate(rate, options = {})
    case rate
    when :unannotated
      s = "Not annotated"
    when :annotated
      s = "Annotated"
    when :reviewed
      s = "Reviewed"
    end

    if options[:checkmark]
      if options[:checkmark] == :only
        c = '&nbsp;'
      else
        c = s
      end

      content_tag(:span, c, :class => rate.to_s)
    else
      s
    end
  end
  # Generates a human readable representation of a relation code.
  def readable_relation(relation)
    "<span class='relation'><abbr title='#{relation.summary.capitalize}'>#{relation.tag}</abbr></span>"
  end

  # Generates a human readable representation of a dependency.
  def readable_dependency(relation, head)
    '(' + readable_relation(relation) + (head ? ", #{head}" : '') + ')'
  end

  # Returns links to external sites for a sentence.
  def external_text_links(sentence)
    # FIXME: hard-coded for now. Change this when I figure out this is
    # really supposed to work.
    keys = sentence.reference_fields.slice("book", "chapter", "verse")

    if keys["chapter"]
      [ link_to('Biblos',     BiblosExternalLinkMapper.instance.to_url(keys), :class => 'external'),
        link_to('bibelen.no', BibelenNOExternalLinkMapper.instance.to_url(keys), :class => 'external'), ] * '&nbsp;';
    else
      ''
    end
  end

  # Generates a rounded box with a description list inside.
  def roundedbox(&block)
    content = capture(&block)
    concat("<div class='roundedbox'><dl>")
    concat(content)
    concat("</dl></div>")
  end

  # Generates a title header and a set of associated links directly
  # next to the header.
  def layer(id, options = {}, &block)
    title = options[:title]
    title ||= id.humanize
    actions = options[:actions]
    actions = "(#{actions.join(' | ')})" if actions

    content = capture(&block)
    concat("<div id='#{id}' class='layer'><h1 class='layer-title'>#{title}</h1> <span class='layer-actions'>#{actions}</span><div class='layer-content'>")
    concat(content)
    concat("</div></div>")
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

  # Formats a token form with HTML language attributes.
  def format_token_form(token)
    LangString.new(token.form, token.language).to_h
  end

  # Formats a lemma form with HTML language attributes.
  def format_lemma_form(lemma)
    LangString.new(lemma.lemma, lemma.language).to_h
  end

  # Formats a language-dependent string with HTML language attributes.
  def format_language_string(s, language)
    LangString.new(s, language).to_h
  end

  # Creates resource links for an object. +actions+ contains a list of
  # actions to present. All links are styled with icons. The links are
  # shown in a specific order regardless of the sequence of actions
  # given in the call.
  #
  # === Actions
  # <tt>:index</tt> -- A link to the index page for the resource.
  # <tt>:new</tt> -- A link for adding a new object.
  # <tt>:edit</tt> -- A link for editing the object.
  # <tt>:delete</tt> -- A link for deleting the object.
  # <tt>:previous</tt> -- A link to the previous object. This is only
  # shown if there is a previous object. This requires the model to
  # respond to +has_previous?+ and +previous+.
  # <tt>:next</tt> -- A link to the next object. This is only shown if
  # there is a next object. This requires the model to respond to
  # +has_next?+ and +next+.
  # <tt>:parent</tt> -- A link to the parent object in a hierarchical
  # structure. This requires the model to respond to +parent+.
  def link_to_resources(object, *actions)
    [:index, :new, :edit, :delete, :previous, :next, :parent].select do |action|
      actions.include?(action)
    end.map do |action|
      send("link_to_#{action}", object)
    end.join(' ')
  end

  # Creates a resource index link for an object.
  def link_to_index(object)
    link_to('Show index', send("#{object.class.to_s.underscore.pluralize}_url"), :class => :index)
  end

  # Creates a resource index link for an object or a model.
  def link_to_new(object_or_model)
    klass = object_or_model.is_a?(Class) ? object_or_model : object_or_model.class
    link_to('New', send("new_#{klass.to_s.underscore}_url"), :class => :new)
  end

  # Creates a resource edit link for an object.
  def link_to_edit(object)
    link_to('Edit', send("edit_#{object.class.to_s.underscore}_url"), :class => :edit)
  end

  # Creates a resource delete link for an object.
  def link_to_delete(object)
    link_to('Delete', object, :method => :delete, :confirm => 'Are you sure?', :class => :delete)
  end

  # Creates a resource previous link for an object. This is only
  # shown if there is a previous object. This requires the model to
  # respond to +has_previous?+ and +previous+. The link will be tied
  # to an access key.
  def link_to_previous(object)
    link_to_if(object.has_previous?, 'Show previous', object.previous, :class => :previous, :accesskey => 'p')
  end

  # Creates a resource next link for an object. This is only shown if
  # there is a next object. This requires the model to respond to
  # +has_next?+ and +next+. The link will be tied to an access key.
  def link_to_next(object)
    link_to_if(object.has_next?, 'Show next', object.next, :class => :next, :accesskey => 'n')
  end

  # Creates a resource parent link for an object. This requires the
  # model to respond to +parent+. The link will be tied to an access
  # key.
  def link_to_parent(object)
    link_to('Show parent', object.parent, :class => :parent, :accesskey => 'u')
  end
end
