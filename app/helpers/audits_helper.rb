module AuditsHelper
  # Creates a summary view of a collection of audits.
  def audits_summary(audits)
    render(:partial => 'audits/legend') +
    content_tag(:ul, render(:partial => 'audits/summary', :collection => audits), :class => 'diff')
  end

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
        link_to_sentence(auditable)
      when Token
        link_to_token(auditable)
      when Lemma
        link_to_lemma(auditable)
      else
        "#{auditable.class} #{auditable.id}"
      end
    else
      "(deleted)"
    end
  end
end
