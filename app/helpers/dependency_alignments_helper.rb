module DependencyAlignmentsHelper
  # Creates a link to dependency alignments for a sentence.
  def link_to_dependency_alignments(sentence, text = nil)
    link_to text || "Sentence #{sentence.id}", annotation_dependency_alignments_path(sentence)
  end
end
