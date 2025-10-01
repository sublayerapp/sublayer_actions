require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It is initialized with recipient email address, sender email address, email subject, and email body (plain text or HTML).
#
# It returns the HTTP response code to confirm the email was sent successfully.
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
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code.to_i
    rescue Exception => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
