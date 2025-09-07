require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# This action integrates with SendGrid's API to send emails.
#
# It is initialized with sender, recipient, subject, and body.
# It returns the HTTP status code to confirm the email was sent successfully.
#
# Example usage: When you want to send notifications, alerts, or automated email campaigns triggered by AI workflows.

class SendGridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:)
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    from = Email.new(email: @sender)
    to = Email.new(email: @recipient)
    content = Content.new(type: 'text/plain', value: @body)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      response.status_code.to_i
    rescue StandardError => e
      error_message = "Error sending SendGrid email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end