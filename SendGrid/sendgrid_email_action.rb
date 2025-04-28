require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails through SendGrid.
# This action supports both plain text and template-based emails with dynamic content,
# making it ideal for sending professional, formatted emails based on AI-generated content.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, and either content or template details.
# It returns the SendGrid API response to confirm the email was sent successfully.
#
# Example usage: When you want to send formatted emails with AI-generated content,
# such as analysis reports, notifications, or personalized communications.

class SendGridEmailAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(
    to_email:,
    subject:,
    content: nil,
    template_id: nil,
    dynamic_template_data: {},
    from_email: nil,
    from_name: nil
  )
    @to_email = to_email
    @subject = subject
    @content = content
    @template_id = template_id
    @dynamic_template_data = dynamic_template_data
    @from_email = from_email || ENV['SENDGRID_FROM_EMAIL']
    @from_name = from_name || ENV['SENDGRID_FROM_NAME']
    @api_key = ENV['SENDGRID_API_KEY']

    validate_parameters!
  end

  def call
    begin
      response = send_email
      log_response(response)
      
      if response.status_code.to_i == 202
        Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_email}")
        response
      else
        error_message = "Failed to send email: HTTP #{response.status_code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_parameters!
    raise ArgumentError, 'Either content or template_id must be provided' if @content.nil? && @template_id.nil?
    raise ArgumentError, 'From email is required' if @from_email.nil?
    raise ArgumentError, 'API key is required' if @api_key.nil?
  end

  def send_email
    sg = SendGrid::API.new(api_key: @api_key)
    
    mail = build_mail
    
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def build_mail
    mail = Mail.new
    mail.from = Email.new(email: @from_email, name: @from_name)
    mail.subject = @subject
    
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to_email))
    
    if @template_id
      mail.template_id = @template_id
      personalization.add_dynamic_template_data(@dynamic_template_data)
    else
      mail.add_content(Content.new(type: 'text/plain', value: @content))
    end
    
    mail.add_personalization(personalization)
    mail
  end

  def log_response(response)
    Sublayer.configuration.logger.log(
      :debug,
      "SendGrid API Response - Status: #{response.status_code}, Body: #{response.body}, Headers: #{response.headers}"
    )
  end
end
