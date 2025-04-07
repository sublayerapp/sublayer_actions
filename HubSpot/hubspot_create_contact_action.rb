require 'uri'
require 'net/http'
require 'json'

# Description: Sublayer::Action responsible for creating a new contact in HubSpot.
# This action helps integrate AI-driven customer insights into CRM systems, 
# aiding marketing and sales efforts by keeping contact databases updated automatically.
#
# Requires: HubSpot API key set in the environment variable 'HUBSPOT_API_KEY'.
#
# It is initialized with contact properties like email, first_name, last_name, etc.
# It raises an error if the contact creation fails.
#
# Example usage: When you generate contact information using AI predictions and 
# want to automatically update your HubSpot CRM.

class HubSpotCreateContactAction < Sublayer::Actions::Base
  def initialize(contact_properties:)
    @contact_properties = contact_properties
    @api_key = ENV['HUBSPOT_API_KEY']
  end

  def call
    create_contact
  rescue StandardError => e
    error_message = "Error creating HubSpot contact: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_contact
    uri = URI.parse("https://api.hubapi.com/contacts/v1/contact?hapikey=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    request.body = { properties: format_properties(@contact_properties) }.to_json

    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      Sublayer.configuration.logger.log(:info, "Successfully created contact in HubSpot")
    else
      error_message = "Failed to create contact: HTTP \\#{response.code} - \\#{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def format_properties(contact_properties)
    contact_properties.map { |key, value| { property: key, value: value } }
  end
end
