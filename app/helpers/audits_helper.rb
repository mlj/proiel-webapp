module AuditsHelper
  # Creates a summary view of a collection of audits.
  def audits_summary(audits)
    render(:partial => 'audits/legend') +
    content_tag(:ul, render(:partial => 'audits/summary', :collection => audits), :class => 'diff')
  end

  # Creates a table view of a collection of audits.
  def audit_table(audits)
    render_tabular audits, :partial => 'audits/audit', :pagination => true, :fields => [ 'User', 'Created at', 'Changed object', '&nbsp;' ]
  end

  # Creates a link to an audit.
  def link_to_audit(audit)
    link_to "Audit #{audit.id}", audit
  end

  # Creates a link to an auditable.
  def link_to_auditable(auditable)
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
  end

  DIFF_NIL_SYMBOL = ''

  def format_change(attribute, old_value, new_value, cell_element = :td)
    case attribute
    when 'sentence_id'
      old_value = old_value ? link_to(old_value, sentence_path(old_value)) : DIFF_NIL_SYMBOL
      new_value = new_value ? link_to(new_value, sentence_path(new_value)) : DIFF_NIL_SYMBOL
    when 'head_id'
      old_value = old_value ? link_to(old_value, token_path(old_value)) : DIFF_NIL_SYMBOL
      new_value = new_value ? link_to(new_value, token_path(new_value)) : DIFF_NIL_SYMBOL
    when 'lemma_id'
      old_value = old_value ? link_to(old_value, lemma_path(old_value)) : DIFF_NIL_SYMBOL
      new_value = new_value ? link_to(new_value, lemma_path(new_value)) : DIFF_NIL_SYMBOL
    end

    content_tag(cell_element, attribute) +
      content_tag(cell_element, old_value || DIFF_NIL_SYMBOL, :class => "removed tag") +
      content_tag(cell_element, new_value || DIFF_NIL_SYMBOL, :class => "added tag")
  end
end
