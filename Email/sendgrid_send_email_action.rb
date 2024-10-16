require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails using the SendGrid API.
# This action allows for easy integration of email sending capabilities into Sublayer workflows.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient_email, subject, email_body (supports HTML formatting), and an optional from_email.
# It returns the SendGrid API response object.
#
# Example usage: When you want to send an email notification or update from an AI process.

class SendGridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, email_body:, from_email: nil)
    @recipient_email = recipient_email
    @subject = subject
    @email_body = email_body
    @from_email = from_email || ENV['SENDGRID_FROM_EMAIL']
    @client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY']).client
  end

  def call
    begin
      mail = SendGrid::Mail.new
      mail.from = SendGrid::Email.new(email: @from_email)
      mail.subject = @subject
      personalization = SendGrid::Personalization.new
      personalization.add_to(SendGrid::Email.new(email: @recipient_email))
      mail.add_personalization(personalization)
      mail.add_content(SendGrid::Content.new(type: 'text/html', value: @email_body))

      response = @client.mail._('send').post(request_body: mail.to_json)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      response # Return the full response object for potential inspection
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end