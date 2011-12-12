module TokensHelper
  # Create a link to a token.
  def link_to_token(token)
    link_to "Token #{token.id}", token
  end
end
