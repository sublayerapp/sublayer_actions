require 'open-uri'
require 'nokogiri'

# Description: Sublayer::Action responsible for summarizing the content of a given URL.
# This action leverages OpenURI and Nokogiri to fetch and parse the URL content,
# then uses OpenAI to generate a summary.

class UrlContentSummarizationAction < Sublayer::Actions::Base
  def initialize(url:, openai_client: nil, openai_model: 'gpt-3.5-turbo')
    @url = url
    @openai_client = openai_client || OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    @openai_model = openai_model
  end

  def call
    begin
      document = Nokogiri::HTML(URI.open(@url))
      text_content = document.text.strip

      if text_content.empty?
        error_message = "No content found at #{@url}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      summary = generate_summary(text_content)

      Sublayer.configuration.logger.log(:info, "Successfully summarized content from #{@url}")
      summary
    rescue OpenURI::HTTPError => e
      error_message = "Error fetching URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error summarizing content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_summary(text)
    response = @openai_client.chat(
      parameters: {
        model: @openai_model,
        messages: [
          { role: 'system', content: 'You are a helpful assistant that summarizes text content.' },
          { role: 'user', content: "Please summarize the following text:\n\n#{text}" }
        ]
      }
    )
    response.dig('choices', 0, 'message', 'content')
  end
end