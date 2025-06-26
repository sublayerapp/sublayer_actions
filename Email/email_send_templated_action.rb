require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending templated emails using SendGrid.
# This action allows for sending emails using predefined templates with dynamic data injection,
# making it perfect for sending AI-generated content through standardized email formats.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with:
# - template_id: The SendGrid template ID to use
# - to_email: Recipient email address
# - dynamic_data: Hash of dynamic template data to inject
# - from_email: (optional) Sender email address (defaults to ENV value)
#
# Returns the SendGrid response ID on success.
#
# Example usage: When you want to send AI-generated content through standardized email templates,
# such as sending analysis reports, notifications, or personalized recommendations.

class EmailSendTemplatedAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(template_id:, to_email:, dynamic_data:, from_email: nil)
    @template_id = template_id
    @to_email = to_email
    @dynamic_data = dynamic_data
    @from_email = from_email || ENV['SENDGRID_FROM_EMAIL']
    @api_key = ENV['SENDGRID_API_KEY']

    validate_initialization_params
  end

  def call
    begin
      response = send_templated_email
      
      if response.status_code.to_i == 202
        message_id = extract_message_id(response)
        Sublayer.configuration.logger.log(:info, "Successfully sent templated email to #{@to_email}. Message ID: #{message_id}")
        message_id
      else
        handle_error_response(response)
      end
    rescue StandardError => e
      error_message = "Error sending templated email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_initialization_params
    raise ArgumentError, 'template_id must be provided' if @template_id.nil? || @template_id.empty?
    raise ArgumentError, 'to_email must be provided' if @to_email.nil? || @to_email.empty?
    raise ArgumentError, 'dynamic_data must be a hash' unless @dynamic_data.is_a?(Hash)
    raise ArgumentError, 'from_email must be provided' if @from_email.nil? || @from_email.empty?
    raise ArgumentError, 'SENDGRID_API_KEY must be set' if @api_key.nil? || @api_key.empty?
  end

  def send_templated_email
    sg = SendGrid::API.new(api_key: @api_key)

    mail = Mail.new
    mail.template_id = @template_id
    
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to_email))
    personalization.add_dynamic_template_data(@dynamic_data)
    
    mail.add_personalization(personalization)
    mail.from = Email.new(email: @from_email)

    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def extract_message_id(response)
    # Extract X-Message-Id from headers if available
    headers = response.headers
    headers['x-message-id'] if headers
  end

  def handle_error_response(response)
    error_message = "Failed to send templated email. Status: #{response.status_code}, Body: #{response.body}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end