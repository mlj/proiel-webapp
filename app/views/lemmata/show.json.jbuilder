json.extract! @lemma, :id, :gloss, :foreign_ids, :language_tag, :part_of_speech_tag
json.form @lemma.export_form
json.semantic_tags @lemma.semantic_tags.map { |t| [t.semantic_attribute.tag, t.semantic_attribute_value.tag].join('=') }
json.similar @lemma.mergeable_lemmata.map(&:id)
json.extract! @lemma, :created_at, :updated_at
