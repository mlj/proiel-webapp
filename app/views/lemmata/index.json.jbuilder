json.lemmata {
  json.array!(@lemmata) do |lemma|
    json.extract! lemma, :id
    json.form lemma.export_form
    json.gloss lemma.gloss
    json.part_of_speech lemma.part_of_speech_tag
    json.url lemma_path(lemma, format: :json)
  end
}
json.count @count
json.page @page
json.pages @pages
