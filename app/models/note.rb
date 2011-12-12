class Note < ActiveRecord::Base
  belongs_to :originator, :polymorphic => true
  belongs_to :notable, :polymorphic => true

  def name_of_originator
    originator.full_name.freeze
  end

  def note_applies_to
    "#{notable.class} #{notable.id}".freeze
  end
end
