require 'restforce'

# Description: Sublayer::Action responsible for creating a record in Salesforce.
# This action allows for integration with Salesforce CRM, supporting automation of record creation based on AI insights.
#
# It is initialized with the object type and a hash of fields to specify the data for the new record.
# It returns the ID of the created record.
#
# Example usage: Automatically creating Salesforce records based on AI-generated insights or customer interactions.

class SalesforceCreateRecordAction < Sublayer::Actions::Base
  def initialize(object_type:, fields: {})
    @object_type = object_type
    @fields = fields
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      host: ENV['SALESFORCE_HOST']
    )
  end

  def call
    begin
      record_id = @client.create!(@object_type, @fields)
      Sublayer.configuration.logger.log(:info, "Salesforce record created successfully with ID: #{record_id}")
      record_id
    rescue Restforce::ErrorResponse => e
      error_message = "Error creating Salesforce record: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "General error creating Salesforce record: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
