require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails via the Gmail API.
# This action allows for integration with Gmail, enabling automated email notifications and communication within Sublayer workflows.
#
# It is initialized with recipient_email, subject, body, and optional attachment and attachment_filename.
# Returns true if message sent successfully, raises exception otherwise.
#
# Example usage: When you want to send an email notification or update from an AI process.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:, attachment: nil, attachment_filename: nil)
    @recipient_email = recipient_email
    @subject = subject
    @body = body
    @attachment = attachment
    @attachment_filename = attachment_filename

    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.send'])
  end

  def call
    begin
      message = build_message
      send_message(message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      true
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def build_message
    msg = Mail.new
    msg.to = @recipient_email
    msg.from = ENV['GMAIL_SENDER_EMAIL']
    msg.subject = @subject
    msg.text_part = @body

    if @attachment
      msg.add_file(filename: @attachment_filename, content: @attachment)
    end

    msg
  end

  def send_message(message)
    begin
      message_object = Google::Apis::GmailV1::Message.new(raw: message.to_s.encode('ASCII-8BIT').force_encoding('BINARY').gsub(/\r\n/, '\n').gsub(/\r/, '').gsub(/\n/, '\r\n'))
      @gmail.send_user_message('me', message_object)
    rescue Google::Apis::ClientError => e
      raise "Error sending email: #{e.message}"
    end
  end
end