module AnnotationsHelper
  # Returns a string identifying the annotator of a sentence, or an
  # empty string if not annotated.
  #
  # ==== Options
  # time:: Include time of actions.
  def format_annotator(sentence, options = {})
    s = ''
    if @sentence.is_annotated?
      s += "Annotated by #{link_to_user(@sentence.annotator)}"
      s += " (#{@sentence.annotated_at})" if options[:time]
    end
    s
  end

  # Returns a string identifying the reviewer of a sentence, or an
  # empty string if not reviewed..
  #
  # ==== Options
  # time:: Include time of actions.
  def format_reviewer(sentence, options = {})
    s = ''
    if @sentence.is_reviewed? 
      s += "Reviewed by #{link_to_user(@sentence.reviewer)}"
      s += " (#{@sentence.reviewed_at})" if options[:time]
    end
    s
  end
end
