require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It is initialized with sender email, recipient email, subject, and email body.
# It returns the response status code to confirm the email was sent successfully.
#
# Example usage: When you want to send email notifications from an AI process.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, email_body:)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @email_body = email_body
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      from = Email.new(email: @sender_email)
      to = Email.new(email: @recipient_email)
      subject = @subject
      content = Content.new(type: 'text/plain', value: @email_body)
      mail = Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: @sendgrid_api_key)
      response = sg.client.mail._('send').post(request_body: mail.to_json)

      if response.status_code.to_i >= 200 && response.status_code.to_i < 300
        Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      else
        error_message = "Failed to send email. HTTP Response Code: #{response.status_code}, Body: #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      response.status_code.to_i
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end