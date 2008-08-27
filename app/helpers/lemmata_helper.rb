module LemmataHelper
  def format_abbreviated_sentence(tokens, limit = 5)
    format_sentence(tokens, :length_limit => limit)
  end

  def link_to_relation(value, options = {})
    if value.is_a?(Token)
      relation = value.relation
    else
      relation = value
    end
    readable_relation(relation)
  end
  
  def link_sentence(sentence, text = nil)
    text ||= sentence.sentence_number
    link_to text, { :controller => 'dependencies', :action => 'show', :id => sentence }, { :class => 'sentence' }
  end
end
