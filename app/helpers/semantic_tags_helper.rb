module SemanticTagsHelper
  # Creates a summary view of a collection of semantic tags.
  def semantic_tags_summary(semantic_tags)
    content_tag(:ul, render(:partial => 'semantic_tags/summary', :collection => semantic_tags))
  end

  # Creates a readable semantic attribute + attribute-value pair.
  def readable_semantic_attribute_value(semantic_attribute, semantic_attribute_value = nil, hlight = nil)
    if semantic_attribute_value.nil?
      content_tag(:span, semantic_attribute.tag, class: :tag)
    else
      content_tag(:span, [semantic_attribute.tag, highlight(semantic_attribute_value.tag, hlight)].join(' = '), class: :tag)
    end
  end

  # Creates a link to a semantic tag taggable.
  def link_to_semantic_tag_taggable(taggable)
    case taggable
    when Token
      link_to "Token #{taggable.id}", taggable.sentence
    when Lemma
      link_to_lemma(taggable)
    else
      raise ArgumentError, "invalid taggable"
    end
  end
end
