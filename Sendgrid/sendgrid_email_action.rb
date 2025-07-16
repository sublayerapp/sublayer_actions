require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails via Sendgrid.
# This action supports HTML content, attachments, and template-based emails.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, and content (either HTML or plain text),
# with optional parameters for CC, BCC, attachments, and template usage.
# It returns the API response status code to confirm the email was sent successfully.
#
# Example usage: When you want an AI agent to send formatted emails, such as reports,
# notifications, or responses to user queries.

class SendgridEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, content: nil, from: nil, cc: [], bcc: [], 
                attachments: [], template_id: nil, template_data: {})
    @to = to
    @subject = subject
    @content = content
    @from = from || ENV['SENDGRID_FROM_EMAIL']
    @cc = Array(cc)
    @bcc = Array(bcc)
    @attachments = Array(attachments)
    @template_id = template_id
    @template_data = template_data
    @api_key = ENV['SENDGRID_API_KEY']

    validate_initialization
  end

  def call
    begin
      response = send_email
      handle_response(response)
    rescue SendGrid::Exception => e
      error_message = "Sendgrid API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_initialization
    raise ArgumentError, 'Sendgrid API key not found' unless @api_key
    raise ArgumentError, 'From email address not specified' unless @from
    raise ArgumentError, 'Either content or template_id must be provided' if !@content && !@template_id
  end

  def send_email
    mail = build_mail
    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def build_mail
    mail = Mail.new
    add_sender(mail)
    add_recipients(mail)
    add_subject(mail)
    add_content(mail) if @content
    add_template(mail) if @template_id
    add_attachments(mail) unless @attachments.empty?
    mail
  end

  def add_sender(mail)
    mail.from = Email.new(email: @from)
  end

  def add_recipients(mail)
    mail.add_personalization(build_personalization)
  end

  def build_personalization
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to))
    
    @cc.each { |cc_address| personalization.add_cc(Email.new(email: cc_address)) }
    @bcc.each { |bcc_address| personalization.add_bcc(Email.new(email: bcc_address)) }
    
    @template_data.each do |key, value|
      personalization.add_dynamic_template_data(key, value)
    end

    personalization
  end

  def add_subject(mail)
    mail.subject = @subject
  end

  def add_content(mail)
    content_type = @content.match?(/<[^>]*>/) ? 'text/html' : 'text/plain'
    mail.add_content(Content.new(type: content_type, value: @content))
  end

  def add_template(mail)
    mail.template_id = @template_id
  end

  def add_attachments(mail)
    @attachments.each do |attachment|
      attachment_content = Base64.strict_encode64(File.read(attachment[:path]))
      mail.add_attachment(
        Attachment.new(
          content: attachment_content,
          type: attachment[:type] || 'application/octet-stream',
          filename: File.basename(attachment[:path]),
          disposition: 'attachment'
        )
      )
    end
  end

  def handle_response(response)
    case response.status_code
    when '202'
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      response.status_code.to_i
    else
      error_message = "Failed to send email. Status code: #{response.status_code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end