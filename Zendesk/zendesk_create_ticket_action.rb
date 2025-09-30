require 'zendesk_api'

# Description: Sublayer::Action responsible for creating a ticket in Zendesk.
# This action enables AI workflows to automatically create customer support tickets
# based on detected issues or user feedback.
#
# Requires: 'zendesk_api' gem
# $ gem install zendesk_api
# Or add `gem 'zendesk_api'` to your Gemfile
#
# It is initialized with ticket details including title, description, priority, and tags.
# It returns the ID of the created Zendesk ticket.
#
# Example usage: When you want to automatically create support tickets from AI-detected issues
# or user feedback analysis.

class ZendeskCreateTicketAction < Sublayer::Actions::Base
  def initialize(title:, description:, priority: 'normal', tags: [], requester_email: nil)
    @title = title
    @description = description
    @priority = priority
    @tags = tags
    @requester_email = requester_email
    
    @client = ZendeskAPI::Client.new do |config|
      config.url = ENV['ZENDESK_URL']
      config.username = ENV['ZENDESK_USERNAME']
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
      subject: @title,
      comment: { body: @description },
      priority: @priority,
      tags: @tags
    }

    # Add requester email if provided
    if @requester_email
      ticket_params[:requester] = { email: @requester_email }
    end

    @client.tickets.create!(ticket_params)
  end
end