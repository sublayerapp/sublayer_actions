require 'salesforce_client'

# Description: Sublayer::Action responsible for creating a new record in Salesforce.
# This action automates the data entry tasks in Salesforce using the REST API.
#
# It is initialized with an object_type and a hash of fields and values to be set on the new record.
# It returns the ID of the created record if successful.
#
# Example usage: When you wish to automate the creation of Salesforce records from LLM-generated outputs or other system integrations.

class SalesforceRecordCreatorAction < Sublayer::Actions::Base
  def initialize(object_type:, fields: {})
    @object_type = object_type
    @fields = fields
    @client = SalesforceClient.new(
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN']
    )
  end

  def call
    begin
      response = @client.create_record(@object_type, @fields)
      if response.success?
        record_id = response.body['id']
        Sublayer.configuration.logger.log(:info, "Salesforce record created successfully with ID: #{record_id}")
        record_id
      else
        handle_error(response)
      end
    rescue StandardError => e
      error_message = "Error creating Salesforce record: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def handle_error(response)
    error_message = "Failed to create Salesforce record: HTTP #{response.code} - #{response.body}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
