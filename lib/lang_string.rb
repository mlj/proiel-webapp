class LangString < String
  attr_reader :lang

  def initialize(s, lang)
    @lang = lang
    super s
  end

  def to_h
    "<span lang=\"#{@lang}\">#{self.to_s}</span>"
  end
end
