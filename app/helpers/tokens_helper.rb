module TokensHelper
  # Creates a table view of a collection of tokens.
  def tokens_table(tokens)
    render_tabular tokens, ['Form', 'Index', 'Part of speech', 'Morphology', 'Lemma', 'Empty sort', '&nbsp;']
  end

  # Create a link to a token.
  def link_to_token(token)
    link_to "Token #{token.id}", token
  end
end
