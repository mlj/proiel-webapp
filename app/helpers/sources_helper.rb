module SourcesHelper
  # Returns a link to a source.
  def link_to_source(source)
    link_to source.title, source
  end

  # Returns a link to an array of sources.
  def link_to_sources(sources)
    sources.map { |l| link_to_source(l) }.to_sentence
  end
end
