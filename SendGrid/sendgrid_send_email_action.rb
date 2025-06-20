require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails using SendGrid's API.
# This action enables sending professional, formatted emails with support for HTML content,
# attachments, and template variables as part of AI-driven workflows.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with required email parameters and optional template data.
# It returns the SendGrid API response to confirm the email was sent successfully.
#
# Example usage: When you want to send AI-generated content via email, such as reports,
# notifications, or customized communications.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(
    to:,
    subject:,
    from: ENV['SENDGRID_FROM_EMAIL'],
    content: nil,
    html_content: nil,
    template_id: nil,
    template_data: {},
    attachments: []
  )
    @to = to
    @from = from
    @subject = subject
    @content = content
    @html_content = html_content
    @template_id = template_id
    @template_data = template_data
    @attachments = attachments
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      
      if response.status_code.to_i == 202
        Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
        response
      else
        error_message = "Failed to send email. Status code: #{response.status_code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      error_message = "Error sending email via SendGrid: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def send_email
    sg = SendGrid::API.new(api_key: @api_key)
    
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject
    
    # Handle multiple recipients if @to is an array
    recipients = @to.is_a?(Array) ? @to : [@to]
    mail.personalizations = recipients.map do |recipient|
      personalization = Personalization.new
      personalization.add_to(Email.new(email: recipient))
      personalization.add_dynamic_template_data(@template_data) unless @template_data.empty?
      personalization
    end

    # Add template ID if provided
    mail.template_id = @template_id if @template_id

    # Add content if no template is used
    unless @template_id
      if @html_content
        mail.add_content(Content.new(type: 'text/html', value: @html_content))
      end
      
      if @content
        mail.add_content(Content.new(type: 'text/plain', value: @content))
      end
    end

    # Add attachments if any
    @attachments.each do |attachment|
      attachment_object = Attachment.new
      attachment_object.content = Base64.strict_encode64(File.read(attachment[:path]))
      attachment_object.type = attachment[:type] || 'application/octet-stream'
      attachment_object.filename = attachment[:filename] || File.basename(attachment[:path])
      attachment_object.disposition = attachment[:disposition] || 'attachment'
      mail.add_attachment(attachment_object)
    end

    sg.client.mail._('send').post(request_body: mail.to_json)
  end
end