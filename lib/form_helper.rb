module MLJ #:nodoc:
  # This requires Rick Olson's labeled_form_helper (and is of course also derived from that).
  class LabeledFormBuilder < ActionView::Helpers::FormBuilder #:nodoc:
    (%w(date_select) +
     ActionView::Helpers::FormHelper.instance_methods - 
     %w(label_for hidden_field check_box radio_button form_for fields_for)).each do |selector|
      src = <<-end_src
        def #{selector}(method, options = {})
          @template.content_tag('p', label_for(options[:label] || method) + super)
        end
      end_src
      class_eval src, __FILE__, __LINE__
    end

    def hidden_field(method, options={})
      super
    end

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      @template.content_tag('p', label_for(method) + "<br />" + super)
    end
    
    def radio_button(method, tag_value, options = {})
      @template.content_tag('p', label_for(method) + "<br />" + super)
    end

    def select(method, choices, options = {}, html_options = {})
      @template.content_tag('p', label_for(method) + "<br />" + super)
    end

    def country_select(method, priority_countries = nil, options = {}, html_options = {})
      @template.content_tag('p', label_for(method) + "<br />" + super)
    end

    def fields_for(object_name, *args, &proc)
      @template.labeled_fields_for(object_name, *args, &proc)
    end
  end
end

ActionView::Base.default_form_builder = MLJ::LabeledFormBuilder
