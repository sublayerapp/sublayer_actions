require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email using SendGrid.
#
# It is initialized with a recipient address, subject, and body (plain text or HTML).
# It returns the response code from the SendGrid API to confirm the email was sent successfully.
#
# Example usage: When you want to send email notifications or updates from an AI process.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_address:, subject:, body:, is_html: false)
    @recipient_address = recipient_address
    @subject = subject
    @body = body
    @is_html = is_html
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_address}")
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def send_email
    from = Email.new(email: ENV['SENDGRID_SENDER_ADDRESS'])
    to = Email.new(email: @recipient_address)
    content = Content.new(type: @is_html ? 'text/html' : 'text/plain', value: @body)
    mail = Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    unless response.status_code.to_i >= 200 && response.status_code.to_i < 300
      error_message = "Failed to send email. HTTP Response Code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    response.status_code.to_i
  end
end
