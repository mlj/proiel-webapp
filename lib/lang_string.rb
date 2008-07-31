class LangString < String
  attr_reader :lang

  def initialize(s, lang, css_class=nil)
    @lang = lang
    @css_class = css_class
    super s
  end

  def to_h
    "<span lang=\"#{@lang}\"#{@css_class ? ' class="' + @css_class + '"' : ''}>#{self.to_s.gsub('<', '&lt;').gsub('>', '&gt;').gsub('\'', '&quot;')}</span>"
  end
end
