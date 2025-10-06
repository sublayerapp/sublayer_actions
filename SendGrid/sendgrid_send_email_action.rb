require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It is initialized with sender email, recipient email, subject, and email body (plain text or HTML).
# It returns the response code to confirm the email was sent successfully.
#
# Example usage: When you want to send notifications, reports, or AI-generated content via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, email_body:, is_html: false)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @email_body = email_body
    @is_html = is_html
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: @is_html ? 'text/html' : 'text/plain', value: @email_body)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code.to_i
    rescue Exception => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
