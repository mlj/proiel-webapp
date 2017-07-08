module AuditsHelper
  # Creates a link to an audit user.
  def link_to_audit_user(user)
    if user
      link_to_user(user)
    else
      'System'
    end
  end

  # Creates a link to an auditable.
  def link_to_auditable(auditable)
    if auditable
      case auditable
      when Sentence
        link_to "Sentence #{auditable.id}", auditable
      when Token
        link_to "Token #{auditable.id}", auditable.sentence
      when Lemma
        link_to "Lemma #{auditable.id}", auditable
      when SourceDivision
        link_to "SourceDivision #{auditable.id}", auditable
      else
        "#{auditable.class} #{auditable.id}"
      end
    else
      "(deleted)"
    end
  end
end
