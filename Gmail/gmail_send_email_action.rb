require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# It takes recipient email, subject, and body as input.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:)
    @recipient_email = recipient_email
    @subject = subject
    @body = body

    @gmail_service = Google::Apis::GmailV1::GmailService.new
    @gmail_service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.send'])
  end

  def call
    begin
      message = build_message
      @gmail_service.send_user_message('me', message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def build_message
    message = Mail.new
    message.to = @recipient_email
    message.from = ENV['GMAIL_SENDER_EMAIL'] || 'me'
    message.subject = @subject
    message.body = @body

    Google::Apis::GmailV1::Message.new(raw: message.to_s.encode('UTF-8').gsub('+', '-').gsub('/', '_').gsub('=', '~'))
  end
end