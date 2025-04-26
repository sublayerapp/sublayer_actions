require 'puppeteer'

# Description: Sublayer::Action responsible for rendering a website to text using Puppeteer.
# This action allows you to extract the visible text content from a website, which can then be used in AI workflows.
#
# It is initialized with a website URL.
# It returns the text content of the rendered website.
#
# Example usage: When you want to analyze the text content of a website, summarize it, or use it as context for an LLM prompt.

class RenderWebsiteToTextAction < Sublayer::Actions::Base
  def initialize(website_url:)
    @website_url = website_url
  end

  def call
    begin
      Puppeteer.launch do |browser|
        page = browser.new_page
        page.goto(@website_url)
        content = page.content
        text = page.evaluate('() => document.body.innerText')

        Sublayer.configuration.logger.log(:info, "Successfully rendered website to text: #{@website_url}")
        text
      end
    rescue Puppeteer::Error => e
      error_message = "Puppeteer error rendering website: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error rendering website to text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end