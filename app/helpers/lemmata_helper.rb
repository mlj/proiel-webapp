module LemmataHelper
  # Creates a table view of a collection of lemmata.
  def lemmata_table(lemmata)
    render_tabular lemmata, [ 'Language', 'Lemma', 'Part of speech', 'Translation', 'Frequency', '&nbsp;' ]
  end

  # Creates a link to a lemma.
  def link_to_lemma(lemma)
    content_tag(:span, link_to(lemma.variant ? "#{lemma.lemma}##{lemma.variant}" : lemma.lemma, lemma), :lang => lemma.language.tag)
  end
end
