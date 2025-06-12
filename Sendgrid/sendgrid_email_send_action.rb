require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails via the SendGrid API.
# This action enables sending AI-generated content, reports, or notifications via email,
# supporting both plain text and HTML content with optional attachments.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with required email parameters (to, from, subject, content)
# and optional parameters (content_type, attachments).
# It returns the SendGrid API response to confirm the email was sent successfully.
#
# Example usage: When you want to send AI-generated reports, analysis results,
# or notifications via email to users or stakeholders.

class SendgridEmailSendAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(to:, from:, subject:, content:, content_type: 'text/plain', attachments: [])
    @to = to
    @from = from
    @subject = subject
    @content = content
    @content_type = content_type
    @attachments = attachments
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      log_response(response)
      response
    rescue StandardError => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject
    
    # Add personalization
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to))
    mail.add_personalization(personalization)

    # Add content
    mail.add_content(Content.new(type: @content_type, value: @content))

    # Add attachments if any
    @attachments.each do |attachment|
      attach = Attachment.new
      attach.content = Base64.strict_encode64(File.read(attachment[:path]))
      attach.type = attachment[:type]
      attach.filename = attachment[:filename]
      attach.disposition = 'attachment'
      mail.add_attachment(attach)
    end

    # Send email
    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def log_response(response)
    case response.status_code
    when '202'
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    else
      Sublayer.configuration.logger.log(:warn, "Unexpected response from SendGrid: #{response.status_code} - #{response.body}")
    end
  end
end