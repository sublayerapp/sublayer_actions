require 'restforce'

# Description: Sublayer::Action responsible for creating a lead in Salesforce.
# This action allows for integration with Salesforce, a leading CRM platform.
# It can be used to automatically create leads based on AI-driven insights.
#
# Requires: 'restforce' gem
# $ gem install restforce
# Or add `gem 'restforce'` to your Gemfile
#
# It is initialized with details like lead name, company, email, and phone.
# It returns the ID of the created Salesforce lead.
#
# Example usage: When you want to create a Salesforce lead based on AI-generated insights or customer data.

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(lead_name:, company:, email: nil, phone: nil)
    @lead_name = lead_name
    @company = company
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET']
    )
    @lead_details = {
      LastName: @lead_name,
      Company: @company,
      Email: email,
      Phone: phone
    }
  end

  def call
    begin
      lead = @client.create('Lead', @lead_details)
      Sublayer.configuration.logger.log(:info, "Salesforce lead created successfully with ID: #{lead}")
      lead
    rescue Restforce::ErrorCode => e
      error_message = "Error creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "General error while creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
