require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails through SendGrid.
# This action enables AI systems to send formatted emails or notifications using SendGrid's API.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, content (can be HTML or plain text),
# and optionally a template_id for using SendGrid templates.
# It returns the API response status code to confirm the email was sent successfully.
#
# Example usage: When you want to send AI-generated content or notifications via email,
# such as sending analysis reports, automated responses, or system notifications.

class SendgridSendEmailAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(to:, subject:, content:, from: nil, template_id: nil, content_type: 'text/html')
    @to = to
    @subject = subject
    @content = content
    @from = from || ENV['SENDGRID_FROM_EMAIL']
    @template_id = template_id
    @content_type = content_type
    @api_key = ENV['SENDGRID_API_KEY']

    validate_parameters
  end

  def call
    begin
      response = send_email
      log_response(response)
      
      if response.status_code.to_i == 202
        Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
        response.status_code.to_i
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

  def validate_parameters
    raise ArgumentError, 'To email address is required' if @to.nil? || @to.empty?
    raise ArgumentError, 'Subject is required' if @subject.nil? || @subject.empty?
    raise ArgumentError, 'Content is required' if @content.nil? || @content.empty?
    raise ArgumentError, 'From email address is required' if @from.nil? || @from.empty?
    raise ArgumentError, 'SendGrid API key is required' if @api_key.nil? || @api_key.empty?
  end

  def send_email
    sg = SendGrid::API.new(api_key: @api_key)

    mail = build_mail
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def build_mail
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject
    
    # Add recipient
    mail.add_personalization(
      Personalization.new.add_to(Email.new(email: @to))
    )

    if @template_id
      mail.template_id = @template_id
      # When using a template, content becomes template data
      mail.add_custom_arg(CustomArg.new(key: 'template_data', value: @content))
    else
      # Add content directly when not using a template
      mail.add_content(
        Content.new(
          type: @content_type,
          value: @content
        )
      )
    end

    mail
  end

  def log_response(response)
    Sublayer.configuration.logger.log(
      :debug,
      "SendGrid API Response - Status: #{response.status_code}, Body: #{response.body}, Headers: #{response.headers}"
    )
  end
end