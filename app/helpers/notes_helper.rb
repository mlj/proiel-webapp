module NotesHelper
  # Creates a summary view of a collection of notes.
  def notes_summary(notes)
    content_tag(:ul, render(:partial => 'notes/summary', :collection => notes))
  end

  # Creates a link to a note originator.
  def link_to_originator(originator)
    case originator
    when User
      link_to_user(originator)
    when ImportSource
      originator.summary
    else
      raise ArgumentError, "Invalid originator"
    end
  end

  # Creates a link to a note notable.
  def link_to_notable(notable)
    case notable
    when Token
      link_to_token(notable)
    when Sentence
      link_to_sentence(notable)
    when Lemma
      link_to_lemma(notable)
    else
      raise ArgumentError, "Invalid originator"
    end
  end
end
