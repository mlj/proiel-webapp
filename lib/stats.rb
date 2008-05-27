UserActivity = Struct.new(:user, 
                          :annotated_sentences, :annotated_tokens,
                          :reviewed_sentences, :reviewed_tokens)

class UserActivity
  def initialize(u)
    self.user = u
    self.annotated_sentences = u.annotated_sentences.count
    self.annotated_tokens = u.annotated_tokens.count
    self.reviewed_sentences = u.reviewed_sentences.count
    self.reviewed_tokens = u.reviewed_tokens.count
  end

  def activity_index
    [self.user.full_name, self.annotated_sentences]
  end

  def is_active?
    self.annotated_tokens > 0 or self.reviewed_tokens > 0
  end
end
