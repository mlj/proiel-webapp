class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject += 'Please activate your new account'
    @body[:activation_url] = SITE_CANONICAL_URL + "/activate/#{user.activation_code}"
  end

  def activation(user)
    setup_email(user)
    @subject += 'Your account has been activated'
    @body[:site_url]  = SITE_CANONICAL_URL 
  end

  protected

  def setup_email(user)
    @recipients = "#{user.email}"
    @from = SITE_ADMINISTRATOR_EMAIL
    @subject = "PROIEL Corpus: "
    @sent_on = Time.now
    @body[:user] = user
  end
end
