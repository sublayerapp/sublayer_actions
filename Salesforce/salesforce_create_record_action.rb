require 'restforce'

# Description: Sublayer::Action responsible for creating a new record in Salesforce.
# This action allows you to automatically add leads or log interactions based on AI-derived insights.
#
# It is initialized with the Salesforce object type, and the fields required for the record.
# It returns the ID of the created Salesforce record.
#
# Example usage: Automatically add leads or log interactions based on LLM outputs.

class SalesforceCreateRecordAction < Sublayer::Actions::Base
  def initialize(object_type:, fields:, **kwargs)
    super(**kwargs)
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
      Sublayer.configuration.logger.log(:info, "Successfully created a new #{@object_type} in Salesforce with ID: #{record_id}")
      record_id
    rescue Restforce::ErrorCode => e
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
