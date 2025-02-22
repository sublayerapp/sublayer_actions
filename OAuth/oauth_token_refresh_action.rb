require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for automatically refreshing OAuth tokens for integrated services in Sublayer.
# This action helps prevent downtime due to token expiration by proactively obtaining new tokens.
#
# It is initialized with client_id, client_secret, refresh_token, and token_url.
# It returns the new access token upon successful refresh.
#
# Example usage: Use this action to refresh OAuth tokens automatically as part of your scheduled workflow to ensure uninterrupted access to services.

class OAuthTokenRefreshAction < Sublayer::Actions::Base
  def initialize(client_id:, client_secret:, refresh_token:, token_url:)
    @client_id = client_id
    @client_secret = client_secret
    @refresh_token = refresh_token
    @token_url = token_url
  end

  def call
    begin
      new_token = refresh_token
      Sublayer.configuration.logger.log(:info, "Successfully refreshed OAuth token.")
      new_token
    rescue StandardError => e
      error_message = "Error refreshing OAuth token: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def refresh_token
    uri = URI.parse(@token_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(
      'client_id' => @client_id,
      'client_secret' => @client_secret,
      'refresh_token' => @refresh_token,
      'grant_type' => 'refresh_token'
    )

    response = http.request(request)
    case response.code.to_i
    when 200..299
      JSON.parse(response.body)['access_token']
    else
      error_message = "Failed to refresh token. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end