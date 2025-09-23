require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It is initialized with recipient email, sender email, subject, and email body (plain text or HTML).
#
# It returns the response code from SendGrid to confirm the email was sent successfully.
#
# Example usage: When you want to send notifications, alerts, or reports from an AI process via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, email_body:)
    @recipient_email = recipient_email
    @sender_email = sender_email
    @subject = subject
    @email_body = email_body
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
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
    subject = @subject
    content = Content.new(type: 'text/html', value: @email_body)
    mail = SendGrid::Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: @sendgrid_api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response.status_code.to_i
    else
      error_message = "Failed to send email. SendGrid Response Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end