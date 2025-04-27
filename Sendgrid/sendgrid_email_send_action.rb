require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails via Sendgrid.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# enabling automated email communications based on AI-generated content or specific triggers.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with to, from, subject, and content parameters for the email.
# It returns the response from Sendgrid to confirm the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or as part of an automated workflow.

class SendgridEmailSendAction < Sublayer::Actions::Base
  include SendGrid

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
      log_success(response)
      response
    rescue StandardError => e
      log_error(e)
      raise e
    end
  end

  private

  def send_email
    mail = prepare_mail
    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def prepare_mail
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to))
    mail.add_personalization(personalization)
    mail.add_content(Content.new(type: 'text/plain', value: @content))
    mail
  end

  def log_success(response)
    Sublayer.configuration.logger.log(:info, "Email sent successfully via Sendgrid. Status code: #{response.status_code}")
  end

  def log_error(error)
    error_message = "Error sending email via Sendgrid: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
  end
end