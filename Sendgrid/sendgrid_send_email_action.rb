require 'sendgrid-ruby'
include SendGrid

# Description: Sublayer::Action responsible for sending emails through Sendgrid.
# This action enables sending formatted emails as part of AI-driven workflows, useful for 
# notifications, reports, or automated responses.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with recipient email, subject, and content (supports both HTML and plain text).
# Optionally accepts a template_id for using Sendgrid Dynamic Templates.
# Returns the API response status code to confirm successful sending.
#
# Example usage: When you want an AI agent to send formatted email notifications,
# reports, or responses to users based on analysis or processed data.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(to_email:, subject:, content:, from_email: nil, template_id: nil, dynamic_template_data: nil)
    @to_email = to_email
    @subject = subject
    @content = content
    @from_email = from_email || ENV['SENDGRID_FROM_EMAIL']
    @template_id = template_id
    @dynamic_template_data = dynamic_template_data
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      log_success(response)
      response.status_code
    rescue SendGrid::Exception => e
      handle_sendgrid_error(e)
    rescue StandardError => e
      handle_general_error(e)
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

    if @template_id
      mail.template_id = @template_id
      personalization.add_dynamic_template_data(@dynamic_template_data) if @dynamic_template_data
    else
      # Determine if content is HTML
      is_html = @content.match?(/<[^>]*>/)
      content_type = is_html ? 'text/html' : 'text/plain'
      mail.add_content(Content.new(type: content_type, value: @content))
    end

    mail
  end

  def log_success(response)
    message = "Successfully sent email to #{@to_email}. Status code: #{response.status_code}"
    Sublayer.configuration.logger.log(:info, message)
  end

  def handle_sendgrid_error(error)
    error_message = "Sendgrid API error: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  def handle_general_error(error)
    error_message = "Error sending email: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end