require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# This action allows for sending emails using SendGrid's API.
#
# It is initialized with a subject, body, and recipient email address.
# It returns the response code from the SendGrid API to confirm the email was sent successfully.
#
# Example usage: When you want to send notifications, alerts, or automated communication from an AI process.

class SendGridSendEmailAction < Sublayer::Actions::Base
  def initialize(subject:, body:, recipient_email:)
    @subject = subject
    @body = body
    @recipient_email = recipient_email
    @sender_email = ENV['SENDGRID_SENDER_EMAIL'] # Ensure this is set in the environment variables
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']   # Ensure this is set in the environment variables
  end

  def call
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    subject = @subject
    content = Content.new(type: 'text/plain', value: @body)
    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: @sendgrid_api_key)
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code.to_i # Returns the HTTP status code
    rescue Exception => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
