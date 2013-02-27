class AuditsResolver < ::ActionView::FileSystemResolver
  def initialize
    super("app/views")
  end

  def find_templates(name, prefix, partial, details)
    super(name, 'audits', partial, details)
  end
end
