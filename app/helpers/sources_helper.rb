module SourcesHelper
  # Returns a link to a source.
  def link_to_source(source)
    link_to source.title, source
  end
end
