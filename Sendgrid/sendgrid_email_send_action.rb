require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails using the Sendgrid API.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# enabling automated email communications based on AI-generated content or triggered by specific conditions.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, and content (HTML or plain text).
# Optionally, you can specify a sender email (defaults to the verified sender in your Sendgrid account).
# It returns the status code of the API response to confirm the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or as part of an automated workflow.

class SendgridEmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, content:, from: nil, content_type: 'text/html')
    @to = to
    @subject = subject
    @content = content
    @from = from || ENV['SENDGRID_FROM_EMAIL']
    @content_type = content_type
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
      SendGrid::Content.new(type: @content_type, value: @content)
    )

    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def log_success(response)
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}. Status code: #{response.status_code}")
  end

  def log_error(error)
    error_message = "Error sending email via Sendgrid: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
  end
end
