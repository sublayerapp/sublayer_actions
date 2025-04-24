# Description: Sublayer::Action responsible for creating a new lead in Salesforce.
# This action streamlines sales processes by automatically creating leads from gathered data or interactions.
#
# It is initialized with lead details such as first name, last name, company, and other optional fields.
# On call execution, it creates a lead in Salesforce and returns the lead ID for verification.
#
# Example usage: Use when you have collected potential customer data and want to create a lead in Salesforce automatically.

require 'restforce'

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(first_name:, last_name:, company:, other_fields: {})
    @first_name = first_name
    @last_name = last_name
    @company = company
    @other_fields = other_fields
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      api_version: '48.0'
    )
  end

  def call
    begin
      lead = @client.create('Lead', lead_params)
      Sublayer.configuration.logger.log(:info, "Lead created successfully in Salesforce: #{lead}")
      lead
    rescue Restforce::ErrorCode::INVALID_OPERATION => e
      error_message = "Salesforce API error when creating lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error in creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def lead_params
    {
      'FirstName' => @first_name,
      'LastName' => @last_name,
      'Company' => @company
    }.merge(@other_fields)
  end
end
