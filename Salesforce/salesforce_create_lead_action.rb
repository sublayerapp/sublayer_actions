require 'restforce'

# Description: Sublayer::Action responsible for creating a new lead in Salesforce.
# This action allows for the automation of importing leads generated through AI-driven insights into Salesforce.
#
# It is initialized with lead details such as last_name, company, email, and other optional fields.
# It returns the ID of the created Salesforce lead.
#
# Example usage: When you want to automatically import a list of AI-generated potential leads into Salesforce for further tracking and engagement.

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(last_name:, company:, email:, lead_details: {})
    @last_name = last_name
    @company = company
    @email = email
    @lead_details = lead_details
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET']
    )
  end

  def call
    lead_data = {
      'LastName' => @last_name,
      'Company' => @company,
      'Email' => @email
    }.merge(@lead_details)

    begin
      lead = @client.create('Lead', lead_data)
      Sublayer.configuration.logger.log(:info, "Salesforce lead created successfully: \\#{lead}")
      lead
    rescue Restforce::ErrorCode => e
      error_message = "Error creating Salesforce lead: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
