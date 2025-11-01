require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails using SendGrid.
# It is initialized with sender_email, recipient_email, subject, and content (both plain text and html).
#
# Example usage: To send notifications, reports, or AI-generated content via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, content_text:, content_html: nil)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @content_text = content_text
    @content_html = content_html
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      true # Return true to indicate success
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    from = Email.new(email: @sender_email)
    to = Email.new(email: @recipient_email)
    subject = @subject

    # Create content.  If HTML is provided, use it, otherwise default to plain text
    if @content_html
      content = Content.new(type: 'text/html', value: @content_html)
    else
       content = Content.new(type: 'text/plain', value: @content_text)
    end

    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: @sendgrid_api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    # Handle possible errors, though SendGrid might accept the request even if it bounces later.
    if response.status_code.to_i >= 400
      error_message = "SendGrid API Error: Status Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    response
  end
end