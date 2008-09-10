module LemmataHelper
  # Creates a table view of a collection of lemmata.
  def lemmata_table(lemmata)
    render_tabular lemmata, :partial => 'lemmata/lemma', :pagination => true, :fields => [ 'Lemma', 'Language', 'Translation', 'Frequency', '&nbsp;' ]
  end

  # Creates a link to a lemma.
  def link_to_lemma(lemma)
    link_to(lemma.variant ? "#{lemma.lemma}##{lemma.variant}" : lemma.lemma, lemma)
  end
end
