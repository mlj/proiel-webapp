module MorphtagsHelper
  # Returns a morphtag select tag for a particular morphtag field in 
  # the morphology palette.
  def morphtag_palette_select_tag(field, id = nil)
    id ||= field.to_s + '_field'
    morphtag_select_tag(id, field, nil, { :style => :summary, :disabled => false })
  end

  # Returns POS formatted in a way which is suitable for the morphtags
  # display.
  def morphtag_pos(token)
    make_nonblank(token.morph.descriptions([:major, :minor], true, :style => :abbreviation).join(', '))
  end

  # Returns non-POS morphology formatted in a way which is suitable for
  # the morphtags display.
  def morphtag_non_pos(token)
    make_nonblank(token.morph.descriptions([:major, :minor], false, :style => :abbreviation).join(', '))
  end
end
