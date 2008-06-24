module MorphtagsHelper
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
