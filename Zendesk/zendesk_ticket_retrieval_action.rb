require 'zendesk_api'

# Description: Sublayer::Action responsible for retrieving support tickets from Zendesk.
# This action can be used to analyze customer support trends or generate resolution suggestions based on ticket data.
#
# Requires: 'zendesk_api' gem
# $ gem install zendesk_api
# Or add `gem 'zendesk_api'` to your Gemfile
#
# It is initialized with a subdomain, username, and token for Zendesk access.
# It retrieves and returns the list of tickets.
#
# Example usage: When you want to analyze support tickets for insights or feed them into an AI model for generating responses.

class ZendeskTicketRetrievalAction < Sublayer::Actions::Base
  def initialize(subdomain:, username:, token:)
    @client = ZendeskAPI::Client.new do |config|
      config.url = "https://\#{subdomain}.zendesk.com/api/v2"
      config.username = username
      config.token = token
    end
  end

  def call
    begin
      tickets = @client.tickets.all
      Sublayer.configuration.logger.log(:info, "Successfully retrieved \\#{tickets.count} tickets from Zendesk")
      tickets
    rescue ZendeskAPI::Error::NetworkError => e
      error_message = "Network error while retrieving tickets from Zendesk: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue ZendeskAPI::Error::ClientError => e
      error_message = "Client error while retrieving tickets from Zendesk: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving tickets from Zendesk: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end