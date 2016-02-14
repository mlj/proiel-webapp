module LayoutHelper
  # Sets the title in the layout.
  def title(page_title, show_title = true)
    @content_for_title = page_title.to_s
    @show_title = show_title
  end

  # True if the title should be visible in the layout.
  def show_title?
    @show_title
  end

  # Inserts javascript files in the layout.
  def javascript(*args)
    content_for(:head) { javascript_include_tag(*args) }
  end

  def message_block(options = {})
    options[:model_error_type] ||= :error
    options[:flash_types] = [:alert, :notice, :back, :confirm, :error, :info, :warn]
    options[:on] ||= controller.controller_name.split('/').last.gsub(/\_controller$/, '').singularize.to_sym
    options[:html] ||= {:id => "message_block", :class => "message_block"}
    options[:html][:id] = options[:id] if options[:id]
    options[:html][:class] = options[:class] if options[:class]
    options[:container] = :div if options[:container].nil?

    flash_messages = {}

    options[:flash_types].each do |type|
      entries = flash[type.to_sym]
      next if entries.nil?
      entries = [entries] unless entries.is_a?(Array)

      flash_messages[type.to_sym] ||= []
      flash_messages[type.to_sym] += entries
    end

    options[:on] = [options[:on]] unless options[:on].is_a?(Array)

    options[:on] = [options[:on]] unless options[:on].is_a?(Array)
    model_objects = options[:on].map do |model_object|
      if model_object == :all
        assigns.values.select {|o| o.respond_to?(:errors) && o.errors.is_a?(ActiveModel::Errors) }
      elsif model_object.instance_of?(String) or model_object.instance_of?(Symbol)
        instance_variable_get("@#{model_object}")
      else
        model_object
      end
    end.flatten.select {|m| !m.nil? }

    model_errors = model_objects.inject([]) {|b, m| b += m.errors.full_messages }

    flash_messages[options[:model_error_type].to_sym] ||= []
    flash_messages[options[:model_error_type].to_sym] += model_errors

    flash_messages.keys.sort_by(&:to_s).select {|type| !flash_messages[type.to_sym].empty? }.map do |type|
      "<ul class=\"#{type}\">" + flash_messages[type.to_sym].map {|message| "<li>#{message}</li>" }.join + "</ul>"
    end.join
    #content_tag(options[:container], contents, options[:html], false)
  end

  def show_message_block?
    !message_block.empty?
  end

  def show_context_bar?
    @show_context_bar
  end

  def context_bar(&block)
    @show_context_bar = true

    content_for(:context_bar) do
      yield
    end
  end
end
