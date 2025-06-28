require 'restforce'

# Description: Sublayer::Action responsible for retrieving account details from Salesforce.
# This action can be used to inform decision-making processes in AI-based applications by
# providing real-time business data insights.
#
# It is initialized with an account_id and retrieves the account details.
#
# Example usage: When you want to get real-time insights about a specific Salesforce account
# for use in an AI-driven workflow.

class SalesforceRetrieveAccountDetailsAction < Sublayer::Actions::Base
  def initialize(account_id:)
    @account_id = account_id
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET']
    )
  end

  def call
    retrieve_account_details
  rescue Restforce::Error => e
    error_message = "Error retrieving account details from Salesforce: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def retrieve_account_details
    account = @client.find('Account', @account_id)
    Sublayer.configuration.logger.log(:info, "Successfully retrieved account details for account ID: #{@account_id}")
    account
  rescue StandardError => e
    error_message = "Failed to retrieve account data: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
