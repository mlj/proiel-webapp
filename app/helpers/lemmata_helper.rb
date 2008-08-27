module LemmataHelper
  # Creates a link to a lemma.
  def link_to_lemma(lemma)
    link_to(lemma.variant ? "#{lemma.lemma}##{lemma.variant}" : lemma.lemma, lemma)
  end
end
