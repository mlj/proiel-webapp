module NotesHelper
  def format_note_originator(originator)
    case originator
    when User
      originator.full_name
    when ImportSource
      originator.summary
    else
      'System'
    end
  end

  # Creates a link to a note notable.
  def link_to_notable(notable)
    case notable
    when Token
      link_to "Token #{notable.id}", notable.sentence
    else
      link_to "#{notable.class} #{notable.id}", notable
    end
  end
end
