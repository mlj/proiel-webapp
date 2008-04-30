class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject = 'PROIEL Corpus account activation'
    @body[:url] = SITE_CANONICAL_URL + "/activate/#{user.activation_code}"
    @body[:login] = user.login
  end
  
  protected
    def setup_email(user)
      @recipients = "#{user.email}"
      @from = SITE_ADMINISTRATOR_EMAIL
      @sent_on = Time.now
      @body[:user] = user
    end
end
