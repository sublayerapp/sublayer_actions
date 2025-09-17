require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It requires a recipient email address, sender email address, subject, and email body (plain text and/or HTML).
#
# It is initialized with the recipient, sender, subject, and content (both plain text and HTML).
# It returns the HTTP status code to confirm the message was sent successfully.
#
# Example usage: When you want to send emails from an AI process, such as notifications, reports, or summaries.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, plain_text_content: nil, html_content: nil)
    @recipient_email = recipient_email
    @sender_email = sender_email
    @subject = subject
    @plain_text_content = plain_text_content
    @html_content = html_content
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    content = Content.new(type: 'text/plain', value: @plain_text_content) if @plain_text_content
    
    mail = Mail.new(from, @subject, to, content)

    if @html_content
      mail.add_content(Content.new(type: 'text/html', value: @html_content))
    end

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
    Sublayer.configuration.logger.log(:error, "Error sending SendGrid email: #{e.message}")
    raise e
  end
end