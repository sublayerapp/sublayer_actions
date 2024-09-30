class Sublayer::Actions::SendEmailAction < Sublayer::Actions::Base
  def initialize(emails:, sender_email:, subject:, body:)
    @emails = emails
    @sender_email = sender_email
    @subject = subject
    @body = body
  end

  def call
    @emails.each do |email|
      send_email(email)
    end
  rescue StandardError => e
    logger.error("Error sending email: #{e.message}")
    raise
  end

  private

  def send_email(email)
    # Implement email sending logic here using your preferred method
    # For example, using a gem like 'mail':
    # mail = Mail.new do
    #   from    @sender_email
    #   to      email
    #   subject @subject
    #   body    @body
    # end
    # mail.deliver!
  end
end