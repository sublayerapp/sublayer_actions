require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# This action allows for sending emails with dynamic content and personalized outreach based on AI insights.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient, sender, subject, and body (text or HTML).
# It returns the response code to confirm the email was sent successfully.
#
# Example usage: When you want to send personalized emails based on AI-generated content or analysis.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient:, sender:, subject:, body:)
    @recipient = recipient
    @sender = sender
    @subject = subject
    @body = body
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      202 # SendGrid returns 202 for accepted
    rescue SendGrid::Exception => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    from = Email.new(email: @sender)
    to = Email.new(email: @recipient)
    subject = @subject
    content = Content.new(type: 'text/html', value: @body)
    mail = SendGrid::Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: @sendgrid_api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    unless response.status_code == '202'
      error_message = "SendGrid API returned an error: #{response.status_code} - #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end