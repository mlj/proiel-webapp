class Bookmark < ActiveRecord::Base
  belongs_to :sentence
  belongs_to :source
  belongs_to :user

  validates_columns :flow

  # Returns the flow bookmark for the user +user+ and the flow +flow+.
  def self.find_flow_bookmark(user, flow)
    Bookmark.find(:first, :conditions => { :flow => flow, :user_id => user })
  end

  # Moves a bookmark one sentence forward and makes any other change necessary
  # to progress one "step" forward in the text. Returns true if successful,
  # false otherwise, i.e. if the end of the available text has been reached.
  def step_bookmark!
    next_sentence = sentence.next_sentence
    if next_sentence
      self.sentence_id = next_sentence.id
      self.save
      true
    else
      false
    end
  end

  protected

  def self.search(query, options = {})
    paginate options
  end
end
