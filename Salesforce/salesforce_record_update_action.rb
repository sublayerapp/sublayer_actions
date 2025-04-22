require 'restforce'

# Description: Sublayer::Action responsible for updating or creating records in Salesforce.
# It allows integration with Salesforce, a popular CRM tool, to update records or create new ones based on AI-generated insights.
#
# It is initialized with object_name, record_id (optional for updating), and fields to update or create.
# It returns the ID of the updated or created record.
#
# Example usage: When you want to update a Salesforce contact record based on new information or create a new lead automatically.

class SalesforceRecordUpdateAction < Sublayer::Actions::Base
  def initialize(object_name:, record_id: nil, fields: {})
    @object_name = object_name
    @record_id = record_id
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
    if @record_id
      update_record
    else
      create_record
    end
  rescue Restforce::Error => e
    error_message = "Salesforce API error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error in SalesforceRecordUpdateAction: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def update_record
    @client.update!(@object_name, { Id: @record_id }.merge(@fields))
    Sublayer.configuration.logger.log(:info, "Successfully updated Salesforce record with ID: #{@record_id}")
    @record_id
  end

  def create_record
    new_record_id = @client.create!(@object_name, @fields)
    Sublayer.configuration.logger.log(:info, "Successfully created Salesforce record with ID: #{new_record_id}")
    new_record_id
  end
end
