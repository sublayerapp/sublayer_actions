require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails using the SendGrid service.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# which can be useful for notifications, updates, or any other email communication needs.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, and body of the email.
# It returns the status code of the email sending operation.
#
# Example usage: When you want to send an email based on AI-generated content or as part of an automated workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:)
    @to = to
    @subject = subject
    @body = body
    @from = ENV['SENDGRID_FROM_EMAIL']
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      response.status_code
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    from = SendGrid::Email.new(email: @from)
    to = SendGrid::Email.new(email: @to)
    content = SendGrid::Content.new(type: 'text/plain', value: @body)
    mail = SendGrid::Mail.new(from, @subject, to, content)

    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end
