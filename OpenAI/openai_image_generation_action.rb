# Description: Sublayer::Action responsible for generating images using OpenAI's DALL-E API.
# It can be used to create visual content based on text descriptions or AI-generated prompts.
#
# Requires: 'openai' gem
# $ gem install openai
# Or
# add `gem 'openai'` to your Gemfile
# and add `require 'openai'` somewhere in your app.
#
# It is initialized with a prompt, size, and number of images to generate.
# It returns an array of image URLs.
#
# Example usage: When you want to generate images based on text descriptions or as part of an AI-driven content creation process.

require 'openai'

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

      image_urls = response.dig('data', 0, 'url')
      Sublayer.configuration.logger.log(:info, "Generated #{@n} image(s) successfully")
      image_urls
    rescue OpenAI::Error => e
      Sublayer.configuration.logger.log(:error, "Error generating images: #{e.message}")
      raise e
    end
  end
end