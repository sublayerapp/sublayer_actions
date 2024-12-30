require 'restforce'

# Description: Sublayer::Action responsible for creating a new lead in Salesforce.
# This action allows integration with Salesforce, a popular CRM platform.
# It can be used to automatically create leads based on LLM-generated insights or user inputs.
#
# Requires: 'restforce' gem
# $ gem install restforce
# Or add `gem 'restforce'` to your Gemfile
#
# It is initialized with a Hash containing lead details such as first_name, last_name, company, and any other lead fields.
# It returns the ID of the created Salesforce lead.
#
# Example usage: When new user data comes from an analysis or an application process, use this action to create a lead in Salesforce.

class SalesforceLeadCreationAction < Sublayer::Actions::Base
  def initialize(lead_details: {})
    @lead_details = lead_details
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      api_version: '52.0'
    )
  end

  def call
    begin
      lead = create_lead
      Sublayer.configuration.logger.log(:info, "Salesforce lead created successfully: \\#{lead.Id}")
      lead.Id
    rescue Restforce::ErrorCode::ERROR_CODE => e
      error_message = "Error creating Salesforce lead: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_lead
    @client.create('Lead', @lead_details)
  end
end
