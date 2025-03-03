require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails through Sendgrid's API.
# This action supports plain text, HTML content, template usage, and attachments.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with required email parameters and optional template/attachment info.
# It returns the response from Sendgrid's API to confirm the email was sent successfully.
#
# Example usage: When you want to send formatted emails or notifications based on AI-generated content,
# such as reports, summaries, or automated responses.

class SendgridSendEmailAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(
    to:,
    from:,
    subject: nil,
    content: nil,
    template_id: nil,
    template_data: nil,
    attachments: nil
  )
    @to = to
    @from = from
    @subject = subject
    @content = content
    @template_id = template_id
    @template_data = template_data
    @attachments = attachments
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      log_response(response)
      response
    rescue StandardError => e
      error_message = "Error sending email via Sendgrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    mail = build_mail
    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def build_mail
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject if @subject

    # Handle single recipient or array of recipients
    recipients = Array(@to).map { |email| Email.new(email: email) }
    mail.personalizations = [Personalization.new(to: recipients)]

    # Add template if specified
    if @template_id
      mail.template_id = @template_id
      mail.personalizations.first.dynamic_template_data = @template_data if @template_data
    else
      # Add content if no template
      if @content
        content_type = @content.match?(/<[^>]*>/) ? 'text/html' : 'text/plain'
        mail.contents = [Content.new(type: content_type, value: @content)]
      end
    end

    # Add attachments if present
    if @attachments
      mail.attachments = build_attachments
    end

    mail
  end

  def build_attachments
    Array(@attachments).map do |attachment|
      Attachment.new(
        content: Base64.strict_encode64(File.read(attachment[:path])),
        type: attachment[:type] || 'application/octet-stream',
        filename: File.basename(attachment[:path]),
        disposition: attachment[:disposition] || 'attachment'
      )
    end
  end

  def log_response(response)
    if response.status_code.to_i.between?(200, 299)
      Sublayer.configuration.logger.log(:info, "Email sent successfully via Sendgrid")
    else
      Sublayer.configuration.logger.log(:warn, "Unexpected response from Sendgrid: #{response.status_code} - #{response.body}")
    end
  end
end