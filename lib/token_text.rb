module TokenText
  PUA_CHARACTERS = {
    "\u{F000}" => '<i>',
    "\u{F100}" => '</i>',

    "\u{F001}" => '<sub>',
    "\u{F101}" => '</sub>',

    "\u{F002}" => '<sup>',
    "\u{F102}" => '</sup>',

    "\u{F003}" => '<b>',
    "\u{F104}" => '</b>',

    "\u{2028}"  => '<br>',

    "\u{2029}"  => '<p>',
  }

  PUA_CHARACTER_REGEXP = Regexp.union(PUA_CHARACTERS.keys)

  def self.token_form_as_html(token_form, single_line: false)
    escaped_token_form = ERB::Util.html_escape(token_form)
    (single_line ? escaped_token_form.gsub(/[\u{2028}\u{2029}]+/, ' ') : escaped_token_form).
      gsub(PUA_CHARACTER_REGEXP, PUA_CHARACTERS)
  end
end
