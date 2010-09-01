class LangString < String
  attr_reader :lang

  def initialize(s, lang, options = {})
    @lang = lang.is_a?(Language) ? lang.tag : lang
    @id = options[:id]
    @css = options[:css]
    super s
  end

  def to_h
    "<span#{@id ? ' id="' + @id + '"' : ''} lang=\"#{@lang}\"#{@css ? ' class="' + @css + '"' : ''}>#{self.to_s.gsub('<', '&lt;').gsub('>', '&gt;').gsub('\'', '&quot;')}</span>"
  end
end
