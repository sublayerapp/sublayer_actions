require 'restforce'

# Description: Sublayer::Action responsible for creating a new lead in Salesforce.
# This action integrates with Salesforce CRM to streamline lead generation processes.
#
# It is initialized with lead details such as last_name, company, email, and other optional fields.
# It returns the ID of the created lead.
#
# Example usage: When you want to integrate lead generation processes with Salesforce CRM from AI-driven insights or customer interactions.

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(last_name:, company:, email: nil, **optional_fields)
    @last_name = last_name
    @company = company
    @optional_fields = optional_fields
    @email = email
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET']
    )
  end

  def call
    begin
      lead = create_lead
      Sublayer.configuration.logger.log(:info, "Salesforce lead created successfully with ID: #{lead.id}")
      lead.id
    rescue Restforce::ErrorCode::INVALID_OPERATION => e
      error_message = "Invalid operation when creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_lead
    @client.create!('Lead', {
      'LastName' => @last_name,
      'Company' => @company,
      'Email' => @email
    }.merge(@optional_fields))
  end
end
