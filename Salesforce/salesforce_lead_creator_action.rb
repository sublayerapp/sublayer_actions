require 'restforce'

# Description: Sublayer::Action responsible for creating new leads in Salesforce.
# This action integrates with Salesforce using the REST API and Restforce gem.
#
# It is initialized with lead data including name, email, company, and any other necessary fields.
# It returns the ID of the created lead.
#
# Example usage: When you want to create a new lead in Salesforce based on data gathered from another source or process.

class SalesforceLeadCreatorAction < Sublayer::Actions::Base
  def initialize(client_id:, client_secret:, username:, password:, security_token:, lead_data:)
    @client_id = client_id
    @client_secret = client_secret
    @username = username
    @password = password
    @security_token = security_token
    @lead_data = lead_data
    @client = Restforce.new(
      username: @username,
      password: @password,
      security_token: @security_token,
      client_id: @client_id,
      client_secret: @client_secret,
      api_version: '52.0'
    )
  end

  def call
    begin
      lead = @client.create('Lead', @lead_data)
      Sublayer.configuration.logger.log(:info, "Lead created successfully in Salesforce with ID: #{lead}")
      lead
    rescue Restforce::ErrorCode::InvalidOperation => e
      error_message = "Error creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
