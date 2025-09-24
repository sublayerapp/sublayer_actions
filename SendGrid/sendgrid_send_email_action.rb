require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email via SendGrid.
#
# It is initialized with sender email, recipient email, subject, and body (both plain text and HTML).
# It returns the response from the SendGrid API.
#
# Example usage: When you want to send emails from an AI-driven process, such as sending reports or notifications.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, plain_text_body:, html_body: nil)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @plain_text_body = plain_text_body
    @html_body = html_body
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      send_email
    rescue SendGrid::Exception => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def send_email
    from = SendGrid::Email.new(email: @sender_email)
    to = SendGrid::Email.new(email: @recipient_email)
    subject = @subject
    content = SendGrid::Content.new(type: 'text/plain', value: @plain_text_body)
    mail = SendGrid::Mail.new(from, subject, to, content)

    if @html_body
      mail.add_content(SendGrid::Content.new(type: 'text/html', value: @html_body))
    end

    sg = SendGrid::API.new(api_key: @sendgrid_api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully via SendGrid to #{@recipient_email}")
    else
      error_message = "Failed to send email via SendGrid. Status Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    response
  end
end