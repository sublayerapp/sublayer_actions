require 'restforce'

# Description: Sublayer::Action responsible for fetching specific data or objects from Salesforce using its API.
# This action allows for integrating CRM data into AI workflows for analysis or updates.
#
# Requires: 'restforce' gem
# $ gem install restforce
# Or add `gem 'restforce'` to your Gemfile
#
# It is initialized with a query for Salesforce.
# It returns the results of the Salesforce query.
#
# Example usage: When you want to analyze Salesforce data or keep updated records based on AI workflows.

class SalesforceDataRetrieverAction < Sublayer::Actions::Base
  def initialize(query:, **kwargs)
    super(**kwargs)
    @query = query
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      host: ENV['SALESFORCE_HOST']
    )
  end

  def call
    begin
      results = @client.query(@query)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved Salesforce data.")
      results
    rescue Restforce::AuthenticationError => e
      error_message = "Authentication failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Restforce::ResponseError => e
      error_message = "Salesforce query error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving Salesforce data: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
