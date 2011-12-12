module LemmataHelper
  # Creates a link to a lemma.
  def link_to_lemma(lemma)
    content_tag(:span, link_to(lemma.variant ? "#{lemma.lemma}##{lemma.variant}" : lemma.lemma, lemma), :lang => lemma.language.tag)
  end
end
