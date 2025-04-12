# Description: Sublayer::Action responsible for creating tickets in Zendesk.
# This action can be utilized to automate customer support workflows,
# where AI-based analysis triages issues and creates corresponding tickets directly in Zendesk,
# helping streamline support operations.
#
# Requires: 'zendesk_api' gem
# $ gem install zendesk_api
# Or add `gem 'zendesk_api'` to your Gemfile
#
# It is initialized with subject, description, priority, and optionally a requester email.
# It returns the ID of the created Zendesk ticket.
#
# Example usage: When you want to automate the creation of tickets in Zendesk based on AI-generated insights.

require 'zendesk_api'

class ZendeskTicketCreationAction < Sublayer::Actions::Base
  def initialize(subject:, description:, priority: 'normal', requester_email: nil)
    @subject = subject
    @description = description
    @priority = priority
    @requester_email = requester_email || ENV['ZENDESK_DEFAULT_REQUESTER_EMAIL']
    @client = ZendeskAPI::Client.new do |config|
      config.url = ENV['ZENDESK_URL']
      config.username = ENV['ZENDESK_USERNAME']
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
    @client.tickets.create!(
      subject: @subject,
      description: @description,
      priority: @priority,
      requester: { email: @requester_email }
    )
  end
end
