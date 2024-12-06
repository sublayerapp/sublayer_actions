require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email using the Sendgrid API.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# enabling automated notifications, follow-ups, or any other email-based communication.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with to, subject, and body parameters, with optional from, cc, and bcc.
# It returns the Sendgrid API response to confirm the email was sent successfully.
#
# Example usage: When you want to send an automated email based on AI analysis or as part of a workflow.

class SendgridEmailSendAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(to:, subject:, body:, from: nil, cc: nil, bcc: nil)
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['SENDGRID_DEFAULT_FROM']
    @cc = cc
    @bcc = bcc
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      response
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to))
    personalization.add_cc(Email.new(email: @cc)) if @cc
    personalization.add_bcc(Email.new(email: @bcc)) if @bcc
    mail.add_personalization(personalization)
    mail.add_content(Content.new(type: 'text/plain', value: @body))

    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end
