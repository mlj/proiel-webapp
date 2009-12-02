module QueriesHelper
  # Generates a search form.
  def search_form_tag(submit_path, options = {}, &block)
    html_options = html_options_for_form(submit_path, :method => 'get', :class => 'search')
    content = capture(&block)
    concat(form_tag_html(html_options))
    concat(content)
    concat(submit_tag(options[:submit] || 'Search', :name => nil) + '</form>'.html_safe)
  end

  def collection_select_tag(method, collection, value_method, text_method, options = {}, html_options = {})
    o = options[:include_blank] ? [['', nil]] : []
    o += collection.map { |x| [x.send(text_method), x.send(value_method)] }
    select_tag(method, options_for_select(o, :selected => params[method] ? params[method].to_i : nil), html_options)
  end

  def query_tag(method)
    text_field_tag method, params[method]
  end

  # Returns a select tag for an association.
  def query_association_tag(association_method, text_method, options = {}, html_options = {})
    klass = association_method.to_s.classify.constantize
    key = (association_method.to_s + '_id').to_sym
    collection_select_tag(key, klass.all, :id, text_method, options, html_options)
  end
end
