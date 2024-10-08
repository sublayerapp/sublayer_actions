require 'net/http'
require 'uri'
require 'json'
require 'openai'

# Description: Sublayer::Action responsible for generating and sharing AI-generated images to a Discord channel.
# This action is ideal for creative teams or communities using Discord for collaboration and inspiration sharing.
#
# It is initialized with a Discord webhook_url, an OpenAI prompt for image generation, and options for image size and count.
# It returns the HTTP response code from Discord to confirm the message was sent successfully.
#
# Example usage: When you want to generate images based on text descriptions and share them directly with a Discord channel.

class DiscordAIImageShareAction < Sublayer::Actions::Base
  def initialize(webhook_url:, prompt:, size: '1024x1024', n: 1)
    @webhook_url = webhook_url
    @prompt = prompt
    @size = size
    @n = n
    @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      image_urls = generate_images
      send_images_to_discord(image_urls)
    rescue StandardError => e
      error_message = "Error in DiscordAIImageShareAction: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def generate_images
    response = @openai_client.images.generate(parameters: {
      prompt: @prompt,
      size: @size,
      n: @n
    })

    image_urls = response['data'].map { |image| image['url'] }
    Sublayer.configuration.logger.log(:info, "Generated #{image_urls.size} images successfully")
    image_urls
  rescue OpenAI::Error => e
    error_message = "Error generating images: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  def send_images_to_discord(image_urls)
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    image_urls.each do |image_url|
      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = 'application/json'
      request.body = { content: image_url }.to_json

      response = http.request(request)
      handle_response(response)
    end
  end

  def handle_response(response)
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Image sent successfully to Discord webhook")
    else
      error_message = "Failed to send image to Discord. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end