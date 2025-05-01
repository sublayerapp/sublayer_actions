require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# Useful for automating email communication and integration into Sublayer agent workflows.
#
# It is initialized with recipient, subject, body, and optional attachments.
# It returns the message ID of the sent email.
#
# Example usage: When you want to send emails from an AI-driven process.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient:, subject:, body:, attachments: [])
    @recipient = recipient
    @subject = subject
    @body = body
    @attachments = attachments

    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.send'])
  end

  def call
    begin
      message = build_message
      sent_message = @gmail.send_user_message('me', message)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}, message ID: #{sent_message.id}")
      sent_message.id
    rescue Google::Apis::ClientError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def build_message
    message = Mail.new
    message.to = @recipient
    message.subject = @subject
    message.from = 'me'
    message.body = @body

    @attachments.each do |attachment_path|
      message.add_file(attachment_path)
    end

    message
  end

end