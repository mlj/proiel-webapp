module LayoutHelper
  # Sets the title in the layout.
  def title(page_title, show_title = true)
    @content_for_title = page_title.to_s

    if show_title
      content_for :title do
        page_title
      end
    end
  end

  # Inserts javascript files in the layout.
  def javascript(*args)
    content_for(:head) { javascript_include_tag(*args) }
  end

  def message_block(options = {})
    flash_messages = {}

    %i(alert notice back confirm error info warn).each do |type|
      entries = flash[type.to_sym]
      next if entries.nil?
      entries = [entries] unless entries.is_a?(Array)

      flash_messages[type.to_sym] ||= []
      flash_messages[type.to_sym] += entries
    end

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

    flash_messages[:error] ||= []
    flash_messages[:error] += model_errors

    messages = {}

    flash_messages.keys.sort_by(&:to_s).each do |type|
      unless flash_messages[type].empty?
        new_type =
          case type
          when :error
            "is-danger"
          when :alert, :warn
            "is-warning"
          when :notice, :info
            "is-success"
          else
            ""
          end

        messages[new_type] ||= []
        messages[new_type] += flash_messages[type]
      end
    end

    if messages.empty?
      ''
    else
      render partial: 'shared/message', locals: { messages_by_type: messages }
    end
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
