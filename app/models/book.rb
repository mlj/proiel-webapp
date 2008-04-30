class Book < ActiveRecord::Base
  has_many :sentences

  # Returns the human-readable presentation form of the name of the source.
  def presentation_form
    self.abbreviation
  end
end
