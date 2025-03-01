require 'restforce'

# Description: Sublayer::Action responsible for creating a new lead record in Salesforce.
# This action facilitates integration with Salesforce for capturing lead information efficiently.
#
# It is initialized with details like name, company, and contact information.
# It returns the ID of the created lead record.
#
# Example usage: When you want to capture lead information from an application or a service and create a Salesforce lead record.

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(name:, company:, email:, phone:, **kwargs)
    super(**kwargs)
    @name = name
    @company = company
    @phone = phone
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      host: ENV['SALESFORCE_HOST']
    )
    @lead_params = {
      LastName: @name,
      Company: @company,
      Email: email,
      Phone: @phone,
    }
  end

  def call
    create_lead
  rescue Restforce::UnauthorizedError => e
    error_message = "Salesforce authentication error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Salesforce lead: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def create_lead
    lead = @client.create('Lead', @lead_params)
    Sublayer.configuration.logger.log(:info, "Lead created successfully in Salesforce with ID: #{lead}")
    lead
  end
end
