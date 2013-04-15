module AnnotationsHelper
  # Returns HTML displaying the annotator of a sentence and the time of
  # annotation.
  def format_annotator_and_time(sentence)
    if sentence.is_annotated?
      t = 'Annotated'
      t += " by #{link_to_user(sentence.annotator)}" if sentence.annotated_by
      t += " on #{sentence.annotated_at.to_s(:long)}" if sentence.annotated_at
    else
      'Not annotated.'
    end
  end

  # Returns HTML displaying the reviewer of a sentence and the time of
  # review.
  def format_reviewer_and_time(sentence)
    if sentence.is_reviewed?
      t = 'Reviewed'
      t += " by #{link_to_user(sentence.reviewer)}" if sentence.reviewed_by
      t += " on #{sentence.reviewed_at.to_s(:long)}" if sentence.reviewed_at
    else
      'Not reviewed.'
    end
  end
end
