# Description: Sublayer::Action responsible for creating a new lead in Salesforce.
# This action enhances CRM functions by automatically creating leads based on AI-analyzed contact or meeting data.
#
# Requires: `restforce` gem
# $ gem install restforce
# Or add `gem 'restforce'` to your Gemfile
#
# It is initialized with lead attributes such as name, company and email.
# It returns the ID of the created Salesforce lead.
#
# Example usage: When AI analyzes meeting details, it can automatically generate new leads in Salesforce.

require 'restforce'

class SalesforceCreateLeadAction < Sublayer::Actions::Base
  def initialize(name:, company:, email:, **kwargs)
    @name = name
    @company = company
    @email = email
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
      lead = create_lead
      Sublayer.configuration.logger.log(:info, "Lead created successfully in Salesforce with ID: #{lead.id}")
      lead.id
    rescue Restforce::ErrorCode => e
      error_message = "Error creating Salesforce lead: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_lead
    @client.create('Lead', {
      FirstName: @name.split(" ").first,
      LastName: @name.split(" ").last,
      Company: @company,
      Email: @email
    })
  end
end
