# Description: Sublayer::Action responsible for extracting specific data points from Salesforce records, such as leads or contacts.
# This action is particularly useful for CRM integrations where contextual data is required for AI processing or decision-making tasks.
#
# It is initialized with a record_id and object_type (e.g., Lead, Contact) and returns the specified data points.
#
# Example usage: When you need to extract specific fields from Salesforce to feed into another AI service for further processing.

require 'salesforce_bulk'

class SalesforceDataExtractorAction < Sublayer::Actions::Base
  def initialize(record_id:, object_type:, fields: [])
    @record_id = record_id
    @object_type = object_type
    @fields = fields
    @client = SalesforceBulk::Client.new(username: ENV['SALESFORCE_USERNAME'],
                                       password: ENV['SALESFORCE_PASSWORD'],
                                       security_token: ENV['SALESFORCE_SECURITY_TOKEN'])
  end

  def call
    query = "SELECT #{@fields.join(', ')} FROM #{@object_type} WHERE Id = '#{@record_id}'"
    response = @client.query(@object_type, query)

    handle_response(response)
  rescue SalesforceBulk::SalesforceError => e
    Sublayer.configuration.logger.log(:error, "Error extracting Salesforce data: #{e.message}")
    raise e
  end

  private

  def handle_response(response)
    result = response.result.records.first
    if result.nil?
      error_message = "No data found for Record ID: #{@record_id}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
    
    Sublayer.configuration.logger.log(:info, "Data extracted successfully for Record ID: #{@record_id}")
    result
  end
end
