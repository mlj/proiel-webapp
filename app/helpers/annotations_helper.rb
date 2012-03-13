module AnnotationsHelper
  # Returns HTML displaying the annotator of a sentence and the time of
  # annotation.
  def format_annotator_and_time(sentence)
    if @sentence.is_annotated?
      t = " on #{@sentence.annotated_at.to_s(:long)}."
      if @sentence.annotator
        "Annotated by #{link_to_user(@sentence.annotator)}" + t
      else
        "Annotated import" + t
      end
    else
      'Not annotated.'
    end
  end

  # Returns HTML displaying the reviewer of a sentence and the time of
  # review.
  def format_reviewer_and_time(sentence)
    if @sentence.is_reviewed?
      t = " on #{@sentence.reviewed_at.to_s(:long)}."
      if @sentence.reviewer
        "Reviewed by #{link_to_user(@sentence.reviewer)}" + t
      else
        "Reviewed import" + t
      end
    else
      'Not reviewed.'
    end
  end
end
