# Description: Sublayer::Action responsible for creating a new lead in Salesforce.
# This action interfaces with the Salesforce API to create leads with specified details such as name, company, email, and phone number.
#
# It is initialized with name, company, email, and phone. It returns the ID of the created lead.
#
# Requires: 'restforce' gem
# $ gem install restforce
# Or add `gem 'restforce'` to your Gemfile
#
# Example usage: When you want to create a new lead in Salesforce based on user inputs or AI-generated suggestions.

require 'restforce'

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(name:, company:, email:, phone:)
    @name = name
    @company = company
    @.email = email
    @phone = phone
    @client = Restforce.new(
      username: ENV['SALESFORCE_USERNAME'],
      password: ENV['SALESFORCE_PASSWORD'],
      security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
      client_id: ENV['SALESFORCE_CLIENT_ID'],
      client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
      api_version: '50.0'
    )
  end

  def call
    begin
      lead = create_lead
      Sublayer.configuration.logger.log(:info, "Lead created successfully in Salesforce with ID: \\#{lead.Id}")
      lead.Id
    rescue Restforce::ErrorCode => e
      error_message = "Salesforce error during lead creation: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "General error during Salesforce lead creation: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_lead
    @client.create('Lead',
                  LastName: @name.split.last,
                  FirstName: @name.split.first,
                  Company: @company,
                  Email: @.email,
                  Phone: @phone)
  end
end
