require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails using SendGrid.
#
# It is initialized with sender_email, recipient_email, subject, and content (which can be plain text or HTML).
# It returns the response status code to confirm if the email was sent successfully.
#
# Example usage: When you want to send email notifications or updates from an AI process.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, content:, content_type: 'text/plain')
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @content = content
    @content_type = content_type
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      send_email
    rescue StandardError => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: @content_type, value: @content)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    else
      error_message = "Failed to send email. HTTP Response Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    response.status_code.to_i
  end
end
