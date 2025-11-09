require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# Requires specifying recipient email address, sender email address, email subject, and email body.
# Useful for sending notifications, reports, or AI-generated content via email.
#
# Requires: sendgrid-ruby gem.
# gem install sendgrid-ruby
#
# It is initialized with recipient_email, sender_email, subject, and body.
# It returns the HTTP status code to confirm the email was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, body:)
    @recipient_email = recipient_email
    @sender_email = sender_email
    @subject = subject
    @body = body
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: 'text/plain', value: @body)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @sendgrid_api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code.to_i
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