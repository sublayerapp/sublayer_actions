require 'openai'

# Description: Sublayer::Action responsible for generating images using OpenAI's DALL-E API.
# This action allows easy integration of AI-generated images into Sublayer workflows,
# expanding the capabilities of text-based generators.
#
# It is initialized with a prompt, size, and optionally the number of images to generate.
# It returns an array of image URLs.
#
# Example usage: When you want to generate images based on text descriptions in your Sublayer workflow.

class OpenAIImageGenerationAction < Sublayer::Actions::Base
  def initialize(prompt:, size: '1024x1024', n: 1)
    @prompt = prompt
    @size = size
    @n = n
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.images.generate(parameters: {
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
  end
end
