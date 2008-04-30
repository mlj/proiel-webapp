module ChangesetsHelper
  def format_change(attribute, old_value, new_value, cell_element = :td)
    case attribute
    when 'head_id'
      old_value = link_to(old_value, token_path(old_value)) if old_value
      new_value = link_to(new_value, token_path(new_value)) if new_value
    when 'lemma_id'
      old_value = link_to(old_value, lemma_path(old_value)) if old_value
      new_value = link_to(new_value, lemma_path(new_value)) if new_value
    end

    [ attribute, old_value, new_value ].zip([nil, :removed, :added]).map do |x| 
      content_tag(cell_element, x[0], :class => x[1]) 
    end
  end
end
