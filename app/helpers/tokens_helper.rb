module TokensHelper
  # Formats the source morphtag of the token +t+. Unless
  # +element+ is overridden, the formatted data will be
  # contained within a span.
  def fmt_morphtag(t, element = 'span')
    classes = ['morphtag']
    if t.morphtag
      classes << 'bad' unless t.morphtag_is_valid?
      content_tag(element, t.morphtag, :class => classes.join(' '))
    else
      content_tag(element, '&nbsp;', :class => classes.join(' '))
    end
  end

  # Formats the source morphtag of the token +t+. Unless
  # +element+ is overridden, the formatted data will be
  # contained within a span.
  def fmt_source_morphtag(t, element = 'span')
    classes = ['morphtag']
    if t.source_morphtag
      classes << 'bad' unless t.source_morphtag_is_valid?
      content_tag(element, t.source_morphtag, :class => classes.join(' '))
    else
      content_tag(element, '&nbsp;', :class => classes.join(' '))
    end
  end
end
