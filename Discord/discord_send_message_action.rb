class DiscordSendMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, message:, username: nil, avatar_url: nil)
    @webhook_url = webhook_url
    @message = message
    @username = username
    @avatar_url = avatar_url
  end

  def call
    begin
      response = HTTParty.post(
        @webhook_url,
        body: {
          content: @message,
          username: @username,
          avatar_url: @avatar_url
        }.to_json,
        headers: {
          'Content-Type' => 'application/json'
        }
      )

      if response.success?
        Sublayer.configuration.logger.log(:info, "Message sent to Discord webhook successfully")
      else
        Sublayer.configuration.logger.log(:error, "Error sending message to Discord webhook: #{response.code} - #{response.body}")
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending message to Discord webhook: #{e.message}")
      raise e
    end
  end
end