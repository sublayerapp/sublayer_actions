# Description: Sublayer::Action responsible for triggering a specified Zapier workflow.
# This action extends Sublayer's integration capabilities, enabling automation with various external services.
#
# It is initialized with a zapier_webhook_url and an optional payload (Hash) containing data to send to the workflow.
# It returns the HTTP response code to confirm the workflow was triggered successfully.
#
# Example usage: When you want to trigger a Zapier workflow as part of a Sublayer process, such as sending data to other apps or automating tasks.

class TriggerZapierWorkflowAction < Sublayer::Actions::Base
  def initialize(zapier_webhook_url:, payload: {})
    @zapier_webhook_url = zapier_webhook_url
    @payload = payload
  end

  def call
    uri = URI.parse(@zapier_webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = @payload.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Zapier workflow triggered successfully")
        response.code.to_i
      else
        error_message = "Failed to trigger Zapier workflow. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zapier workflow: #{e.message}")
      raise e
    end
  end
end