require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for extracting structured data from a given URL using web scraping.
#
# It is initialized with a URL and returns a hash containing extracted data such as title, author, publication date, and summary.
#
# Example usage: When you want to process information from web pages in an AI agent workflow.

class WebScraper::ExtractStructuredDataFromURLAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      
      data = {
        title: extract_title(doc),
        author: extract_author(doc),
        publication_date: extract_publication_date(doc),
        summary: extract_summary(doc)
      }

      Sublayer.configuration.logger.log(:info, "Successfully extracted data from \#{@url}")
      data
    rescue OpenURI::HTTPError => e
      error_message = "HTTP error while accessing URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::Error => e
      error_message = "Error parsing HTML content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting data from URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_title(doc)
    doc.title
  rescue StandardError => e
    Sublayer.configuration.logger.log(:warn, "Could not extract title: \#{e.message}")
    nil
  end

  def extract_author(doc)
    # Attempt to extract author from meta tags or other common patterns
    author = doc.at_css('meta[name="author"]')['content'] rescue nil
    author ||= doc.at_css('meta[name="dc.creator"]')['content'] rescue nil
    author
  rescue StandardError => e
    Sublayer.configuration.logger.log(:warn, "Could not extract author: \#{e.message}")
    nil
  end

  def extract_publication_date(doc)
    # Attempt to extract publication date from meta tags or other common patterns
    date = doc.at_css('meta[name="publication_date"]')['content'] rescue nil
    date ||= doc.at_css('meta[name="date"]')['content'] rescue nil
    date ||= doc.at_css('meta[property="article:published_time"]')['content'] rescue nil

    Date.parse(date) if date
  rescue StandardError => e
    Sublayer.configuration.logger.log(:warn, "Could not extract publication date: \#{e.message}")
    nil
  end

  def extract_summary(doc)
    # Attempt to extract summary from meta tags
    summary = doc.at_css('meta[name="description"]')['content'] rescue nil
    summary ||= doc.at_css('meta[name="og:description"]')['content'] rescue nil
    summary
  rescue StandardError => e
    Sublayer.configuration.logger.log(:warn, "Could not extract summary: \#{e.message}")
    nil
  end
end