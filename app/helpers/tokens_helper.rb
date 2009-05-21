module TokensHelper
  # Creates a table view of a collection of tokens.
  def tokens_table(tokens)
    render_tabular tokens, [ 'Form', 'Linearisation index', 'Sort', 'Part of speech', 'Morphology', 'Lemma', '&nbsp;' ]
  end

  # Create a link to a token.
  def link_to_token(token)
    link_to "Token #{token.id}", token
  end

  def readable_presentation_flags(t)
    flags = []
    [:contraction, :emendation, :abbreviation, :capitalisation].each do |flag|
      flags << flag.to_s if t.send(flag)
    end
    flags.join(', ')
  end
end
