require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending email using SendGrid.
# It can be used for notifications, alerts, or updates coming from AI-driven processes.
#
# It is initialized with recipient_email, subject, and content.
# It logs the success or failure of the email sending operation.
#
# Example usage: When you want to send notifications or updates via email as part of a Sublayer workflow.

class EmailSendGridEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, content:, from_email: 'default@example.com')
    @recipient_email = recipient_email
    @subject = subject
    @content = content
    @from_email = from_email
    @client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  end

  def call
    mail = build_email
    send_mail(mail)
  rescue StandardError => e
    error_message = "Error sending email via SendGrid: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def build_email
    from = Email.new(email: @from_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: 'text/plain', value: @content)
    Mail.new(from, @subject, to, content)
  end

  def send_mail(mail)
    response = @client.client.mail._('send').post(request_body: mail.to_json)
    if response.status_code.to_i.between?(200, 299)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    else
      error_message = "Failed to send email: HTTP #{response.status_code} - #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end