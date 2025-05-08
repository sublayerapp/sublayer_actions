require 'zohocrm_ruby'

# Description: Sublayer::Action that automates the creation of leads in Zoho CRM.
# This action is useful for sales teams to track potential clients based on extracted data or user interactions.
#
# It is initialized with lead details such as name, email, and phone number, with optional parameters for additional data.
# It returns the ID of the created lead in Zoho CRM.
#
# Example usage: When you extract potential client data and want to seamlessly add them as leads to track in Zoho CRM.

class ZohoCRMLeadCreationAction < Sublayer::Actions::Base
  def initialize(name:, email:, phone:, additional_data: {})
    @name = name
    @email = email
    @phone = phone
    @additional_data = additional_data
    @client = ZohoCRM::Client.new(token: ENV['ZOHO_CRM_ACCESS_TOKEN'])
  end

  def call
    begin
      response = create_lead
      lead_id = response['id']
      Sublayer.configuration.logger.log(:info, "Lead created successfully in Zoho CRM with ID: #{lead_id}")
      lead_id
    rescue ZohoCRM::Error => e
      error_message = "Error creating lead in Zoho CRM: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "An unexpected error occurred: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_lead
    lead_data = {
      'First_Name' => @name.split.first,
      'Last_Name' => @name.split.last,
      'Email' => @email,
      'Phone' => @phone
    }.merge(@additional_data)

    @client.create_record('Leads', lead_data)
  end
end