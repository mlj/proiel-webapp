module TablesHelper
  def render_tabular(collection, options = {})
    fields = options[:fields]
    pg = if options[:pagination]
           "<div class='page_info'>" + page_entries_info(collection) + "</div>" + (will_paginate(collection) || "")
         else
           ''
         end
    hd = fields ? content_tag(:thead, content_tag(:tr, fields.map { |field| "<th>#{field}</th>" })) : ''
    if options[:partial]
      bd = content_tag(:tbody, render(:partial => options[:partial], :collection => collection))
    else
      bd = content_tag(:tbody, render(:partial => collection))
    end
    if options[:new]
      l = (['&nbsp;'] * (fields.length - 1)) + [link_to('Add new', options[:new])]
      ft = content_tag(:tfoot, l.map { |field| "<td>#{field}</td>" })
    else
      ft = ''
    end
    content_tag(:div, pg + content_tag(:table, hd + bd + ft, :class => options[:class]), :class => 'tabular')
  end
end
