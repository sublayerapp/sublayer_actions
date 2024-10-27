require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails using the Sendgrid API.
# This action allows for automated, personalized email communications based on AI-generated content
# or triggered by specific events in a Sublayer workflow.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with the recipient's email, subject, and content of the email.
# Optionally, you can specify a sender email (defaults to the one set in SendGrid settings).
# It returns the status code of the API response to confirm the email was sent successfully.
#
# Example usage: When you want to send personalized emails based on AI-generated content or
# notifications from your Sublayer workflow.

class SendgridEmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, content:, from: nil)
    @to = to
    @subject = subject
    @content = content
    @from = from || ENV['SENDGRID_FROM_EMAIL']
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      log_success(response)
      response.status_code
    rescue StandardError => e
      log_error(e)
      raise e
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

  def log_success(response)
    Sublayer.configuration.logger.log(
      :info,
      "Email sent successfully to #{@to}. Status code: #{response.status_code}"
    )
  end

  def log_error(error)
    error_message = "Error sending email via Sendgrid: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
  end
end