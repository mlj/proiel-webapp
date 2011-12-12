class ActionView::Template
  class Redcarpet
    def self.call(template)
      @@markdown ||= ::Redcarpet::Markdown.new(::Redcarpet::Render::HTML,
        :space_after_headers => true)
      @@markdown.render(template.source).inspect
    end
  end

  register_template_handler :markdown, Redcarpet
end
