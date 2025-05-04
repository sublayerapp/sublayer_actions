require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails using the SendGrid API.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# enabling automatic notifications, reports, or other AI-generated content to be sent via email.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with to, from, subject, and content parameters for the email.
# It returns the SendGrid API response to confirm the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or notifications from your Sublayer workflow.

class SendGridEmailSendAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, content:)
    @to = to
    @from = from
    @subject = subject
    @content = content
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      response
    rescue StandardError => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    sg = SendGrid::API.new(api_key: @api_key)
    
    mail = SendGrid::Mail.new(
      SendGrid::Email.new(email: @from),
      @subject,
      SendGrid::Email.new(email: @to),
      SendGrid::Content.new(type: 'text/plain', value: @content)
    )
    
    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end
