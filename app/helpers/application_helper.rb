# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++

module ApplicationHelper
  # Returns true if the current user is an administrator.
  def is_administrator?
    current_user.try(:has_role?, :administrator)
  end

  # Returns true if the current user is a reviewer.
  def is_reviewer?
    current_user.try(:has_role?, :reviewer)
  end

  # Returns true if the current user is an annotator.
  def is_annotator?
    current_user.try(:has_role?, :annotator)
  end

  # Returns true if the current user is a reader.
  def is_reader?
    current_user.try(:has_role?, :reader)
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

  # Generates a human readable representation of a completion rate/sentence
  # status.
  def completion_rate(rate)
    content_tag(:span, '', :class => rate.to_s)
  end

  # Generates a human readable representation of a relation code.
  def readable_relation(relation)
    "<span class='relation'><abbr title='#{relation.summary.capitalize}'>#{relation.tag}</abbr></span>"
  end

  # Returns links to external sites for a sentence.
  def external_text_links(sentence)
    [BiblosExternalLinkMapper].map do |l|
      url = l.instance.to_url(sentence.citation)
      if url
        link_to(l.instance.site_name, url)
      else
        nil
      end
    end.compact * ' '
  end

  # Returns links to exporters of a sentence.
  #
  # FIXME: generate LaTeX directly and hide using JS so that we don't need a separate controller call
  def export_links(obj)
    if obj.is_a?(Sentence)
      link_to('Export to LaTeX', action: 'export')
    else
      ''
    end
  end

  # Generates a rounded box with a description list inside.
  def roundedbox(object = nil, &block)
    content = capture(&block)
    concat("<div class='roundedbox'><dl style='float: left; width: 90%'>".html_safe)
    concat(content)
    concat("</dl><br style='clear: both' /></div>".html_safe)
  end

  # Formats a token form with HTML language attributes.
  def format_token_form(token)
    content_tag(:span, TokenText.token_form_as_html(token.form).html_safe, lang: token.language.to_s)
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
    link_to('Index', send("#{object.class.to_s.underscore.pluralize}_url"))
  end

  # Creates a resource index link for an object or a model.
  def link_to_new(object_or_model)
    klass = object_or_model.is_a?(Class) ? object_or_model : object_or_model.class
    link_to('New', send("new_#{klass.to_s.underscore}_url"))
  end

  # Creates a resource edit link for an object.
  def link_to_edit(object)
    link_to('Edit', send("edit_#{object.class.to_s.underscore}_url"))
  end

  # Creates a resource delete link for an object.
  def link_to_delete(object)
    link_to('Delete', object, method: :delete, confirm: 'Are you sure?')
  end

  # Creates a resource previous link for an object. This is only
  # shown if there is a previous object. This requires the model to
  # respond to +has_previous?+ and +previous+. The link will be tied
  # to an access key.
  def link_to_previous(object)
    if object.has_previous?
      link_to('Previous', object.previous_object, accesskey: 'p')
    end
  end

  # Creates a resource next link for an object. This is only shown if
  # there is a next object. This requires the model to respond to
  # +has_next?+ and +next+. The link will be tied to an access key.
  def link_to_next(object)
    if object.has_next?
      link_to('Next', object.next_object, accesskey: 'n')
    end
  end

  # Creates a resource parent link for an object. This requires the
  # model to respond to +parent+. The link will be tied to an access
  # key.
  def link_to_parent(object)
    link_to('Parent', object.parent, accesskey: 'u')
  end

  def breadcrumb_title_for(object)
    case object
    when Source
      object.author_and_title
    when SourceDivision
      object.title
    when Sentence
      "Sentence #{object.id}"
    when Token
      "Token #{object.id}"
    when Lemma
      content_tag(:em, object.export_form, lang: object.language_tag) +
        " (#{object.pos_summary})" +
        (@lemma.gloss ? " '#{@lemma.gloss}'" : "")
    when Note
      "Note #{object.id}"
    when String
      object
    else
      raise ArgumentError, "invalid class #{object.class}"
    end
  end

  def breadcrumb_link_to(object)
    if object.is_a?(String)
      object
    elsif object.is_a?(Array)
      link_to(*object)
    else
      link_to(breadcrumb_title_for(object), object)
    end
  end

  def breadcrumbs(*objects)
    *parents, current = objects
    crumbs = parents.map { |o| breadcrumb_link_to(o) }
    crumbs << breadcrumb_title_for(current)
    b = crumbs.map { |c| "<li>#{c}</li>" }.join(' » ')
    content_for(:breadcrumbs) do
      "<ol class=\"breadcrumbs\">#{b}</ol>".html_safe
    end
  end

  def search_language_tags
    Source.represented_languages
  end

  def search_sources
    Source.all.sort_by(&:to_label)
  end

  def search_status_tags
    StatusTag.all.map { |t| [t.to_label, t.tag] }
  end

  def search_part_of_speech_tags
    Lemma.represented_parts_of_speech
  end

  def search_relation_tags
    RelationTag.all.map { |t| [t.to_label, t.tag] }
  end

  def search_information_status_tags
    InformationStatusTag.all.map { |t| [t.to_label, t.tag] }
  end

  def search_morphology_field_tags(field)
    MorphFeatures::MORPHOLOGY_SUMMARIES[field].map { |x, y| [y, x] }
  end
end
