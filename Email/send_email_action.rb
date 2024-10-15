require 'sendgrid-ruby'

# Description: Sublayer::Action for sending emails using the SendGrid API.
# This action can be used to automate email communications triggered by AI processes,
# such as sending AI-generated reports or notifications.
#
# Requires: `sendgrid-ruby` gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with the sender email, recipient details (array of emails),
# subject, and email body content. You can also provide optional parameters like cc and bcc.
# It returns the SendGrid API response object for detailed information.
#
# Example usage: When you want to send an AI-generated report or notification via email.

class SendEmailAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_emails:, subject:, body:, cc: [], bcc: [])
    @sender_email = sender_email
    @recipient_emails = recipient_emails
    @subject = subject
    @body = body
    @cc = cc
    @bcc = bcc
    @sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  end

  def call
    begin
      mail = SendGrid::Mail.new
      mail.from = SendGrid::Email.new(email: @sender_email)
      mail.subject = @subject
      mail.add_personalizations(create_personalizations)
      mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @body))

      response = @sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully - Response Code: #{response.status_code}")
      response
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def create_personalizations
    personalization = SendGrid::Personalization.new
    @recipient_emails.each { |email| personalization.add_to(SendGrid::Email.new(email: email)) }
    @cc.each { |email| personalization.add_cc(SendGrid::Email.new(email: email)) }
    @bcc.each { |email| personalization.add_bcc(SendGrid::Email.new(email: email)) }
    personalization
  end
end