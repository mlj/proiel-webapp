module AlignmentsHelper
  # Formats a sentence for the alignment views. If +value+ is +nil+,
  # instead inserts a non-breaking space. If +klass+ is not +nil+,
  # the sentence is presented in a +span+ of class +klass+.
  def format_sentence_for_alignment(value, klass = nil)
    if value.is_a?(Array)
      value.collect do |s|
        format_sentence(s, { :verse_numbers => :all, :tooltip => :morphtags })
      end.join(' ')
    elsif value.is_a?(NilClass)
    else
      format_sentence(value, { :verse_numbers => :all, :tooltip => :morphtags })
    end
  end

  # Makes an "expand sentence" link for the alignment views.
  def make_expand_sentence_link(action)
    link_to_remote "+", :update => 'body', 
      :url => { :action => 'edit', 
        :id => @sentence, 
        :modifications => @modifications + [action.to_s], 
        :_context => params[:_context] },
      :html => { :title => 'Expand sentence' }
  end

  # Makes a "shorten sentence" link for the alignment views.
  def make_shorten_sentence_link(action)
    link_to_remote "-", :update => 'body', 
      :url => { :action => 'edit', 
        :id => @sentence, 
        :modifications => @modifications + [action.to_s], 
        :_context => params[:_context] }, 
      :html => { :title => 'Shorten sentence' }
  end
end
