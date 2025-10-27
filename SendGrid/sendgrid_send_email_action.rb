require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It is initialized with recipient_email, sender_email, subject, and body.
# It returns the response from SendGrid to confirm the message was sent successfully.
#
# Example usage: When you want to send notifications or reports from an AI process via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, body:)
    @recipient_email = recipient_email
    @sender_email = sender_email
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
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code
    rescue Exception => e
      error_message = "Error sending SendGrid email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
