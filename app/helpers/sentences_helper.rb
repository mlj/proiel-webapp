module SentencesHelper
  # Creates a link to a sentence.
  def link_to_sentence(sentence)
    link_to "Sentence #{sentence.id}", sentence
  end
end
