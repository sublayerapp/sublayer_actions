# Description: Sublayer::Action responsible for sending emails using SendGrid.
# This action allows for integration with SendGrid to send emails from within a Sublayer workflow.
#
# It is initialized with recipient email, sender email, subject, and message body.
# It returns the SendGrid response to confirm the email was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process.

class SendGridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, message_body:)
    @recipient_email = recipient_email
    @sender_email = sender_email
    @subject = subject
    @message_body = message_body
    @client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  end

  def call
    begin
      mail = SendGrid::Mail.new
      mail.from = SendGrid::Email.new(email: @sender_email)
      personalization = SendGrid::Personalization.new
      personalization.add_to(SendGrid::Email.new(email: @recipient_email))
      mail.add_personalization(personalization)
      mail.subject = @subject
      mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @message_body))

      response = @client.client.mail._("send").post(request_body: mail.to_json)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code
    rescue JSON::ParserError => e
      Sublayer.configuration.logger.log(:error, "Error parsing JSON response from SendGrid: #{e.message}")
      raise e
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Sublayer.configuration.logger.log(:error, "Timeout error communicating with SendGrid: #{e.message}")
      raise e
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end