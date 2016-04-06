json.tokens {
  json.array!(@tokens) do |token|
    json.extract! token, :id, :form, :citation, :sentence_id

    json.left format_sentence(token.previous_objects, length_limit: -5, single_line: true)
    json.right format_sentence(token.next_objects, length_limit: 5, single_line: true)
    json.match format_token_form(token)
  end
}
json.count @count
json.page @page
json.pages @pages

