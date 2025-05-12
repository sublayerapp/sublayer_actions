require 'zendesk_api'

# Description: Sublayer::Action responsible for creating and managing tickets in Zendesk.
# This action facilitates the automation and management of customer support tasks via Zendesk.
#
# It is initialized with subdomain, email, and token for authentication, along with ticket details such as subject, description, and optional fields.
# It returns the ticket ID of the created ticket.
#
# Example usage: When you want to automate the creation of tickets in Zendesk based on AI-generated insights from customer interactions.

class ZendeskTicketAutomatorAction < Sublayer::Actions::Base
  def initialize(subdomain:, email:, token:, subject:, description:, optional_fields: {})
    @subdomain = subdomain
    @email = email
    @token = token
    @subject = subject
    @description = description
    @optional_fields = optional_fields
    @client = ZendeskAPI::Client.new do |config|
      config.url = "https://#{@subdomain}.zendesk.com/api/v2"
      config.username = @email
      config.token = @token
    end
  end

  def call
    begin
      ticket = create_ticket
      Sublayer.configuration.logger.log(:info, "Zendesk ticket created successfully with ID: #{ticket.id}")
      ticket.id
    rescue ZendeskAPI::Error::ClientError => e
      error_message = "Error creating Zendesk ticket: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_ticket
    @client.tickets.create!(
      subject: @subject,
      description: @description,
      **@optional_fields
    )
  end
end