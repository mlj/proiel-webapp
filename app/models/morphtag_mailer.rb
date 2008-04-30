class MorphtagMailer < ActionMailer::Base
  def failed_morphtag_notification(token)
    setup_email(token)
    @subject = 'PROIEL Corpus: Morphtagger failed '
  end
  
  protected
    def setup_email(token)
      @recipients = SITE_ADMINISTRATOR_EMAIL
      @from = SITE_ADMINISTRATOR_EMAIL
      @sent_on = Time.now
      @body[:id] = token.id
      @body[:sid] = token.sentence.id
      @body[:form] = token.form
      @body[:morphtag] = token.morphtag
    end
end
