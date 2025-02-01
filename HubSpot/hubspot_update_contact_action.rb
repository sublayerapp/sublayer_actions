require 'hubspot-api-client'

# Description: This Sublayer::Action is responsible for updating contact information in HubSpot CRM.
# This ensures AI-driven insights and data updates are immediately reflected in the CRM system.
#
# It is initialized with contact_id and properties (a hash of fields to update).
#
# Example usage: When you have new insights about a lead from an AI and want to reflect those updates in HubSpot.

class HubSpotUpdateContactAction < Sublayer::Actions::Base
  def initialize(contact_id:, properties: {})
    @contact_id = contact_id
    @properties = properties
    configure_hubspot_client
  end

  def call
    begin
      update_contact
      Sublayer.configuration.logger.log(:info, "Successfully updated contact \\#{@contact_id} in HubSpot")
    rescue Hubspot::Crm::Contacts::ApiError => e
      error_message = "Error updating contact: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def configure_hubspot_client
    Hubspot.configure do |config|
      config.api_key['hapikey'] = ENV['HUBSPOT_API_KEY']
    end
  end

  def update_contact
    api_instance = Hubspot::Crm::Contacts::BasicApi.new
    api_instance.update(@contact_id, { properties: @properties })
  end
end
