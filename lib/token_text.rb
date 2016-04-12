module TokenText
  PUA_CHARACTERS = {
    "\u{F0000}" => '<i>',
    "\u{F0100}" => '</i>',

    "\u{F0001}" => '<sub>',
    "\u{F0101}" => '</sub>',

    "\u{F0002}" => '<sup>',
    "\u{F0102}" => '</sup>',

    "\u{F0003}" => '<b>',
    "\u{F0104}" => '</b>',

    "\u{2028}"  => '<br>',

    "\u{2029}"  => '<p>',
  }

  PUA_CHARACTER_REGEXP = Regexp.union(PUA_CHARACTERS.keys)

  def self.token_form_as_html(token_form, single_line: false)
    (single_line ? token_form.gsub(/[\u{2028}\u{2029}]+/, ' ') : token_form).
      gsub(PUA_CHARACTER_REGEXP, PUA_CHARACTERS)
  end
end
