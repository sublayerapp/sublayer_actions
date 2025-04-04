require 'open_uri'
require 'nokogiri'
require 'openai'

# Description: Sublayer::Action responsible for summarizing the content of a webpage given a URL.
# It uses the Nokogiri gem to parse the HTML content and OpenAI's API to generate the summary.
#
# It is initialized with a url and returns a summary of the webpage content.
#
# Example usage: When you want to quickly understand the content of a webpage without fully parsing it.

class SummarizeWebpageAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      content = fetch_and_extract_text(@url)
      summary = summarize_text(content)
      Sublayer.configuration.logger.log(:info, "Successfully summarized webpage at \#{@url}")
      summary
    rescue OpenURI::HTTPError => e
      error_message = "Error fetching webpage: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue OpenAI::Error => e
      error_message = "Error summarizing webpage: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during webpage summarization: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def fetch_and_extract_text(url)
    html = URI.open(url).read
    doc = Nokogiri::HTML(html)
    # Extract text from the body, but remove script and style elements
    doc.xpath('//body//text()').remove_if { |node| node.parent.name.match?(/^(script|style)$/) }.to_s.gsub(/\s+/, ' ').strip
  end

  def summarize_text(text)
    response = @client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: 'You are a helpful assistant that summarizes web pages concisely.'
          },
          {
            role: 'user',
            content: "Summarize the following text from a webpage: \n\n #{text}"
          }
        ],
        temperature: 0.5
      }
    )
    response.dig('choices', 0, 'message', 'content').strip
  end
end