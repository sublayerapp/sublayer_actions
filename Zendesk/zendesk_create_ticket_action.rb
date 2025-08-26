require 'zendesk_api'

# Description: Sublayer::Action responsible for creating support tickets in Zendesk.
# This action enables the creation of tickets with custom fields, tags, and priority levels.
#
# Requires: 'zendesk_api' gem
# $ gem install zendesk_api
# Or add `gem 'zendesk_api'` to your Gemfile
#
# It is initialized with required ticket details (subject, description, priority)
# and optional parameters (custom_fields, tags).
# It returns the ID of the created Zendesk ticket.
#
# Example usage: When you want to automatically create support tickets based on
# AI-analyzed customer feedback or automated issue detection.

class ZendeskCreateTicketAction < Sublayer::Actions::Base
  def initialize(subject:, description:, priority: 'normal', custom_fields: {}, tags: [])
    @subject = subject
    @description = description
    @priority = priority
    @custom_fields = custom_fields
    @tags = tags
    @client = ZendeskAPI::Client.new do |config|
      config.url = ENV['ZENDESK_URL'] # https://your-subdomain.zendesk.com/api/v2
      config.username = ENV['ZENDESK_EMAIL']
      config.token = ENV['ZENDESK_API_TOKEN']
    end
  end

  def call
    begin
      ticket = create_ticket
      Sublayer.configuration.logger.log(:info, "Successfully created Zendesk ticket ##{ticket.id}")
      ticket.id
    rescue ZendeskAPI::Error::NetworkError => e
      error_message = "Network error creating Zendesk ticket: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue ZendeskAPI::Error::RecordInvalid => e
      error_message = "Invalid ticket data: #{e.message}"
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
    ticket_params = {
      subject: @subject,
      description: @description,
      priority: @priority,
      tags: @tags
    }

    # Add custom fields if provided
    ticket_params[:custom_fields] = @custom_fields unless @custom_fields.empty?

    @client.tickets.create!(ticket_params)
  end
end