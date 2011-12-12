module WizardHelper
  def remaining_assigned_sentences
    pluralize(current_user.assigned_sentences.count, 'sentence')
  end
end
