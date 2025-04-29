require 'zapier' 

# Description: Sublayer::Action to trigger a Zap on Zapier, allowing interaction with various third-party apps.
# It uses the `zapier` gem to communicate with the Zapier API.
#
# It is initialized with a webhook_url (your Zapier webhook URL) and a payload (data to send to the Zap).
# It returns the HTTP response code from Zapier to confirm the trigger was successful.
#
# Example usage: When you want an AI agent to automatically create a new Trello card based on specific conditions
# or log information to a Google Sheet.

class ZapierTriggerZapAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {})
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    begin
      response = Zapier.trigger(@webhook_url, @payload)

      if response.success?
        Sublayer.configuration.logger.log(:info, "Zap triggered successfully with response: #{response.body}")
        response.code
      else
        error_message = "Failed to trigger Zap. Response: #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zap: #{e.message}")
      raise e
    end
  end
end