require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# Requires SendGrid API key, sender email, recipient email, subject, and body.
#
# It is initialized with a sender email, recipient email, subject and body.
# It returns the SendGrid response to confirm the message was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, body:)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @body = body
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: 'text/plain', value: @body)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response
    else
      error_message = "Failed to send email to #{@recipient_email}. HTTP Response Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error sending SendGrid email: #{e.message}")
    raise e
  end
end
