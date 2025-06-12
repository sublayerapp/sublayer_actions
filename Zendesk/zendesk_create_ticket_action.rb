require 'zendesk_api'

# Description: Sublayer::Action responsible for creating a ticket in Zendesk.
# This action facilitates the automation of helpdesk or customer support tickets based on AI-driven insights.
#
# It is initialized with the subject, description, priority, and optional assignee_id.
# It returns the ticket ID of the created ticket.
#
# Example usage: When you want to create a support ticket in Zendesk automatically after analyzing customer feedback or detecting an issue.

class ZendeskCreateTicketAction < Sublayer::Actions::Base
  def initialize(subject:, description:, priority:, assignee_id: nil)
    @subject = subject
    @description = description
    @priority = priority
    @assignee_id = assignee_id
    @client = ZendeskAPI::Client.new do |config|
      config.url = ENV['ZENDESK_URL']
      config.username = ENV['ZENDESK_USERNAME']
      config.token = ENV['ZENDESK_API_TOKEN']
    end
  end

  def call
    begin
      ticket = create_ticket
      Sublayer.configuration.logger.log(:info, "Zendesk ticket created successfully: #{ticket.id}")
      ticket.id
    rescue ZendeskAPI::Error::NetworkError => e
      error_message = "Network error during Zendesk ticket creation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating Zendesk ticket: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_ticket
    ticket = @client.tickets.create(
      subject: @subject,
      description: @description,
      priority: @priority,
      assignee_id: @assignee_id
    )
    ticket
  end
end
