require 'restforce'

# Description: Sublayer::Action responsible for updating existing Salesforce leads with new information.
# This action can be integrated into workflows to enrich lead records with additional data.
#
# Requires: 'restforce' gem
# $ gem install restforce
#
# It is initialized with a lead_id and a hash of fields containing the update data.
# It returns the updated lead information if successful.
#
# Example usage: When you need to update Salesforce leads with new insights or updates from an AI-driven workflow.

class SalesforceLeadUpdateAction < Sublayer::Actions::Base
  def initialize(lead_id:, fields: {})
    @lead_id = lead_id
    @fields = fields
    @client = Restforce.new
  end

  def call
    begin
      update_lead
      Sublayer.configuration.logger.log(:info, "Lead updated successfully in Salesforce with ID: #{@lead_id}")
      @client.find('Lead', @lead_id)
    rescue Restforce::Error => e
      error_message = "Error updating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def update_lead
    @client.update('Lead', { Id: @lead_id }.merge(@fields))
  end
end
