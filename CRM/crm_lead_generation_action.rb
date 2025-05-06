require 'salesforce_client' # hypothetical client or adapter for Salesforce
# require 'hubspot_client'   # hypothetical client or adapter for HubSpot

# Description: Sublayer::Action responsible for creating new leads in a CRM system like Salesforce or HubSpot.
# This action utilizes AI-generated data to populate lead information into the specified CRM system.
#
# It is initialized with crm_type, lead_data, and optionally api_credentials.
# It returns the ID of the created lead.
#
# Example usage: When AI generates potential customer data and you want to add these as new leads into your existing CRM for follow-up.

class CRMLeadGenerationAction < Sublayer::Actions::Base
  def initialize(crm_type:, lead_data:, api_credentials: {})
    @crm_type = crm_type.downcase
    @lead_data = lead_data
    @api_credentials = api_credentials
    @client = initialize_client
  end

  def call
    create_lead
  rescue StandardError => e
    error_message = "Error creating CRM lead: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def initialize_client
    case @crm_type
    when 'salesforce'
      SalesforceClient.new(@api_credentials)
    when 'hubspot'
      # HubspotClient.new(@api_credentials) # Uncomment and implement if using HubSpot
    else
      raise "Unsupported CRM type: \\#{@crm_type}"
    end
  end

  def create_lead
    case @crm_type
    when 'salesforce'
      response = @client.create_lead(@lead_data)
    when 'hubspot'
      # response = @client.create_lead(@lead_data) # Uncomment and implement if using HubSpot
    else
      raise "Unsupported CRM type: \\#{@crm_type}"
    end
    response['id'] || response # Return lead ID or whole response if ID unavailable
  end
end
