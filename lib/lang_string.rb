class LangString < String
  attr_reader :lang

  def initialize(s, lang)
    @lang = lang
    super s
  end

  def to_h
    "<span lang=\"#{@lang}\">#{self.to_s.gsub('<', '&lt;').gsub('>', '&gt;').gsub('\'', '&quot;')}</span>"
  end
end
