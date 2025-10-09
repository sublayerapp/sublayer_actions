require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email using SendGrid.
# It can be used for sending notifications, reports, or updates from AI-driven processes.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or
# add `gem 'sendgrid-ruby'` to your gemfile
# and add `requires 'sendgrid-ruby'` somewhere in your app.
#
# It is initialized with to_email, from_email, subject, and body.
# It returns the response from the SendGrid API to confirm it was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process via email.

class SendGridSendEmailAction < Sublayer::Actions::Base
  def initialize(to_email:, from_email:, subject:, body:)
    @to_email = to_email
    @from_email = from_email
    @subject = subject
    @body = body
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      send_email
    rescue SendGrid::Exception => e
      error_message = "Error sending SendGrid email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    from = SendGrid::Email.new(email: @from_email)
    to = SendGrid::Email.new(email: @to_email)
    subject = @subject
    content = SendGrid::Content.new(type: 'text/plain', value: @body)
    mail = SendGrid::Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    if response.status_code.to_i >= 200 && response.status_code.to_i < 300
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_email}")
      response
    else
      error_message = "Failed to send email. HTTP Response Code: #{response.status_code} - #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end