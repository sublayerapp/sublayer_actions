require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails via Sendgrid.
# This action allows for sending emails using the Sendgrid API, making it easy to integrate
# email communications into AI-driven workflows.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, and content (plus optional parameters).
# It returns the response from Sendgrid to confirm the email was sent successfully.
#
# Example usage: When you want to send AI-generated reports, notifications, or automated
# communications via email using Sendgrid.

class SendgridSendEmailAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(to_email:, subject:, content:, template_id: nil, from_email: nil, content_type: 'text/html')
    @to_email = to_email
    @subject = subject
    @content = content
    @template_id = template_id
    @from_email = from_email || ENV['SENDGRID_FROM_EMAIL']
    @content_type = content_type
    @api_key = ENV['SENDGRID_API_KEY']

    raise StandardError, 'SENDGRID_API_KEY environment variable is required' unless @api_key
    raise StandardError, 'From email address is required' unless @from_email
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
    mail.from = Email.new(email: @from_email)
    mail.subject = @subject
    
    # Add recipient
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to_email))
    mail.add_personalization(personalization)

    # Add template if provided, otherwise add content
    if @template_id
      mail.template_id = @template_id
    else
      mail.add_content(Content.new(type: @content_type, value: @content))
    end

    mail
  end

  def log_response(response)
    case response.status_code
    when '202'
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_email}")
    else
      Sublayer.configuration.logger.log(:warn, "Unexpected response from Sendgrid: #{response.status_code} - #{response.body}")
    end
  end
end
