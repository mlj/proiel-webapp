module SentencesHelper
  # Creates a link to a sentence.
  def link_to_sentence(sentence, text = nil)
    link_to text || "Sentence #{sentence.id}", sentence
  end
end
