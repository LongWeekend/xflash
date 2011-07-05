class UserMailer < ActionMailer::Base
  def signup(user, domain, sent_at = Time.now)
    @title    = 'Welcome to Nihongopedia'[:text_welcome_to_npedia]
    @body       = {:user => user, :domain => domain}
    @recipients = user.email
    @from       = 'noreply@' + domain.split(":").first
    @sent_on    = sent_at
    @headers    = {}
  end
end