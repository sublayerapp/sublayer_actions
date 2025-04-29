require 'watir'
require 'webdrivers'

# Description: Sublayer::Action for web scraping, retrieving content from dynamic pages.
# Uses Watir for browser automation and supports JavaScript execution.
#
# Example usage: Extract data from websites to use in prompts or trigger other actions based on web content.

class WebScrapingAction < Sublayer::Actions::Base
  def initialize(url:, css_selector:, timeout: 30)
    @url = url
    @css_selector = css_selector
    @timeout = timeout
  end

  def call
    begin
      browser = Watir::Browser.new :chrome, headless: true
      browser.goto(@url)
      browser.wait_until(timeout: @timeout) { browser.element(css: @css_selector).exists? }
      content = browser.element(css: @css_selector).text.strip
      browser.close

      Sublayer.configuration.logger.log(:info, "Successfully scraped content from #{@url}")
      content
    rescue Watir::Wait::TimeoutError => e
      error_message = "Timeout waiting for element: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during web scraping: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end