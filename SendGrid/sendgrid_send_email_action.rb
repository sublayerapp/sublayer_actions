require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails using SendGrid.
# This action allows sending customized emails with options for recipient, sender, subject, and body (both plain text and HTML).
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient, sender, subject, and either plain text content or HTML content (or both).
# It returns the HTTP response code to confirm the email was sent successfully.
#
# Example usage: When you want to send transactional emails, notifications, or updates from an AI process.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient:, sender:, subject:, plain_text_content: nil, html_content: nil)
    @recipient = recipient
    @sender = sender
    @subject = subject
    @plain_text_content = plain_text_content
    @html_content = html_content
    @sendgrid_api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      from = Email.new(email: @sender)
      to = Email.new(email: @recipient)
      subject = @subject

      if @plain_text_content && @html_content
        content = Content.new(type: 'text/plain', value: @plain_text_content)
        html_content = Content.new(type: 'text/html', value: @html_content)
        mail = Mail.new(from, subject, to, content)
        mail.add_content(html_content)
      elsif @plain_text_content
        content = Content.new(type: 'text/plain', value: @plain_text_content)
        mail = Mail.new(from, subject, to, content)
      elsif @html_content
        content = Content.new(type: 'text/html', value: @html_content)
        mail = Mail.new(from, subject, to, content)
      else
        raise ArgumentError, 'Either plain_text_content or html_content must be provided'
      end

      sg = SendGrid::API.new(api_key: @sendgrid_api_key)
      response = sg.client.mail._('send').post(request_body: mail.to_json)

      if response.status_code.to_i >= 200 && response.status_code.to_i < 300
        Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
        response.status_code.to_i
      else
        error_message = "Failed to send email. HTTP Response Code: #{response.status_code}, Body: #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

    rescue SendGrid::Exception => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end