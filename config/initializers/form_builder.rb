ActionView::Base.default_form_builder = SemanticFormBuilder

# Just a little bit of monkeypatching to get us up and running with collection_select.
class SemanticFormBuilder
  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    field_name, label, options = field_settings(method, options)
    choices = collection.map do |element|
      [element.send(text_method), element.send(value_method)]
    end
    select_box = this_check_box = @template.select(@object_name, method, choices, options.merge(:object => @object), html_options)
    wrapping("collection-select", field_name, label, select_box, options)    
  end
end

# ...and have properly humanised labels
class SemanticFormBuilder
  def field_settings(method, options = {}, tag_value = nil)
    field_name = "#{@object_name}_#{method.to_s}"
    default_label = tag_value.nil? ? "#{method.to_s.gsub(/\_/, " ")}" : "#{tag_value.to_s.gsub(/\_/, " ")}"
    label = options[:label] ? options.delete(:label) : default_label.humanize
    options[:class] ||= ""
    options[:class] += options[:required] ? " required" : ""
    label += "<strong><sup>*</sup></strong>" if options[:required]
    [field_name, label, options]
  end
end
