require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It is initialized with sender email, recipient email, subject, and email body (plain text or HTML).
# It returns the SendGrid message ID.
#
# Example usage: When you want to send automated emails based on AI-generated content or events.

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
    begin
      send_email
    rescue SendGrid::Exception => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error occurred while sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def send_email
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: @is_html ? 'text/html' : 'text/plain', value: @email_body)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.headers['X-Message-Id']&.first # Return SendGrid message ID, if available
    else
      error_message = "Failed to send email.  Status Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end