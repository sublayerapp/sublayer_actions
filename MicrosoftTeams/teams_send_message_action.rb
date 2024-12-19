require 'microsoft_teams'

# Description: Sublayer::Action responsible for sending a message to a specific Microsoft Teams channel or chat.
# This action can be used for instant communication and updates from AI-driven processes.
#
# It is initialized with a webhook_url and a message.
# It returns a confirmation message on successful sending.
#
# Example usage: When you want to send a notification or update from an AI process to a Microsoft Teams channel or chat.

class TeamsSendMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, message:)
    @webhook_url = webhook_url
    @message = message
  end

  def call
    begin
      send_message_to_teams
      Sublayer.configuration.logger.log(:info, "Message sent successfully to Microsoft Teams")
      "Message sent successfully to Microsoft Teams"
    rescue StandardError => e
      error_message = "Error sending Microsoft Teams message: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_message_to_teams
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = { text: @message }.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError, "Failed to send message to Microsoft Teams. HTTP Response Code: \\#{response.code}"
    end
  end
end
