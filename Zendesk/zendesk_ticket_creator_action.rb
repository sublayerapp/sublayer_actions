require 'zendesk_api'

# Description: Sublayer::Action responsible for creating a ticket in Zendesk based on error logs or customer feedback.
# This action allows for seamless integration of customer support into automated workflows.
#
# Requires: 'zendesk_api' gem
# $ gem install zendesk_api
# Or add `gem 'zendesk_api'` to your Gemfile
#
# It is initialized with a subject, description, and optionally a priority, requester_email, and type.
# It returns the ID of the created Zendesk ticket.
#
# Example usage: When you want to automatically create support tickets in Zendesk from AI-generated insights or user feedback.

class ZendeskTicketCreatorAction < Sublayer::Actions::Base
  def initialize(subject:, description:, priority: 'normal', requester_email: nil, type: 'problem')
    @subject = subject
    @description = description
    @priority = priority
    @requester_email = requester_email
    @type = type
    @client = ZendeskAPI::Client.new do |config|
      config.url = ENV['ZENDESK_API_URL']
      config.username = ENV['ZENDESK_EMAIL']
      config.token = ENV['ZENDESK_API_TOKEN']
    end
  end

  def call
    begin
      ticket = create_ticket
      Sublayer.configuration.logger.log(:info, "Zendesk ticket created successfully with ID: #{ticket.id}")
      ticket.id
    rescue ZendeskAPI::Error::NetworkError => e
      error_message = "Network error during ticket creation: #{e.message}"
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
    @client.tickets.create(
      subject: @subject,
      description: @description,
      priority: @priority,
      requester: { email: @requester_email || ENV['DEFAULT_REQUESTER_EMAIL'] },
      type: @type
    )
  end
end
