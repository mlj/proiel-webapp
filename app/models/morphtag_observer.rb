class MorphtagObserver < ActiveRecord::Observer
  observe :token

  def after_update(token)
    if token.morphtag_performance == :failed
      MorphtagMailer.deliver_failed_morphtag_notification(token)
    end
  end
end
