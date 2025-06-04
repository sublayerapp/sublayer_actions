require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending formatted emails through Sendgrid's API.
# This action provides a simple interface for sending emails with support for HTML content,
# attachments, and templates using the Sendgrid service.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient details, subject, and content, with optional template and attachment support.
# It returns the response from Sendgrid's API to confirm the email was sent successfully.
#
# Example usage: When you want to send AI-generated reports, notifications, or follow-ups via email.
# This could include sending analysis results, scheduled reports, or automated responses.

class SendgridEmailSendAction < Sublayer::Actions::Base
  def initialize(
    to_email:,
    subject:,
    content:,
    from_email: nil,
    content_type: 'text/html',
    template_id: nil,
    template_data: nil,
    attachments: []
  )
    @to_email = to_email
    @from_email = from_email || ENV['SENDGRID_FROM_EMAIL']
    @subject = subject
    @content = content
    @content_type = content_type
    @template_id = template_id
    @template_data = template_data
    @attachments = attachments
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      handle_response(response)
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
    mail.from = Email.new(email: @from_email)
    mail.subject = @subject
    
    # Add recipient
    mail.add_personalization(build_personalization)

    # Add content or template
    if @template_id
      mail.template_id = @template_id
    else
      mail.add_content(Content.new(type: @content_type, value: @content))
    end

    # Add attachments if any
    @attachments.each do |attachment|
      add_attachment(mail, attachment)
    end

    mail
  end

  def build_personalization
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to_email))
    
    if @template_id && @template_data
      @template_data.each do |key, value|
        personalization.add_dynamic_template_data(key, value)
      end
    end

    personalization
  end

  def add_attachment(mail, attachment)
    attached_file = Attachment.new
    attached_file.content = Base64.strict_encode64(File.read(attachment[:path]))
    attached_file.type = attachment[:type]
    attached_file.filename = attachment[:filename]
    attached_file.disposition = attachment[:disposition] || 'attachment'
    
    mail.add_attachment(attached_file)
  end

  def handle_response(response)
    case response.status_code
    when '202'
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_email}")
      response
    else
      error_message = "Failed to send email. Status code: #{response.status_code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end