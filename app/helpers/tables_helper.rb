module TablesHelper
  def render_tabular(collection, fields, options = {})
    render :partial => 'generic/table', :locals => {
      :fields => fields,
      :partial => options[:partial],
      :no_pagination => options[:no_pagination],
      :new => options[:new],
      :css_class => options[:css_class],
      :collection => collection,
    }
  end
end
