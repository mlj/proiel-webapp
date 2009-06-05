#
# external_link_mapper.rb - Mapping to external site URLs
#
# Written by Marius L. Jøhndal, 2007, 2008.
#
require 'yaml'
require 'singleton'

class ExternalLinkMapper
  include Singleton

  def initialize(identifier)
    datadir = File.expand_path(File.dirname(__FILE__))
    definition = YAML::load_file(File.join(datadir, File.basename(__FILE__).sub(/rb$/, 'yml')))
    raise "Cannot find definition for #{identifier}" unless definition.has_key?(identifier)
    @book_mapping = definition[identifier][:books]
    @base_url = definition[identifier][:url]
  end
end

# A mapping class for references to Biblos URLs.
class BiblosExternalLinkMapper < ExternalLinkMapper
  def initialize
    super 'biblos'
  end

  def to_url(ref)
    book, chapter, verse = @book_mapping[ref["book"]], ref["chapter"], ref["verse"]

    if chapter and verse
      "#{@base_url}#{book}/#{chapter}-#{verse}.htm"
    else
      "#{@base_url}#{book}/"
    end
  end
end

class BibelenNOExternalLinkMapper < ExternalLinkMapper
  def initialize
    super 'bibelen.no'
  end

  def to_url(ref)
    book, chapter, verse = @book_mapping[ref["book"]], ref["chapter"], ref["verse"]

    if chapter
      "#{@base_url}chapter.aspx?book=#{book}&chapter=#{chapter}"
    else
      "#{@base_url}chapter.aspx?book=#{book}"
    end
  end
end
