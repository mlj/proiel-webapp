module SemanticRelationsHelper
  # Creates a summary view of a collection of semantic relations.
  def semantic_relations_summary(semantic_relations)
      content_tag(:ul, render(:partial => 'semantic_relations/summary', :collection => semantic_relations))
  end

  # Creates a readable semantic relation
  def readable_semantic_relation(semantic_relation_type, semantic_relation_tag, controller_token, target_token, hlight = nil)
    par = [link_to(controller_token.id, controller_token), link_to(target_token.id, target_token) ].map(&:to_s).join(',')
    STDERR.puts content_tag(:span, [semantic_relation_type.tag, highlight(semantic_relation_tag.tag, hlight)].join(' = ') + '(' + par + ')', {:class => 'tag'}, false)
    content_tag(:span, [semantic_relation_type.tag, highlight(semantic_relation_tag.tag, hlight)].join(' = ') + '(' + par + ')', {:class => 'tag'}, false)
  end
end
