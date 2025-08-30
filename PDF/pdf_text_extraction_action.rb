require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files while preserving
# document structure, handling tables, and maintaining formatting information.
#
# This action provides a clean interface for processing PDF documents before sending their content
# to language models for analysis or processing.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a path to the PDF file and optional parameters for controlling the extraction.
# Returns a structured hash containing the extracted text content with metadata.
#
# Example usage: When you want to process PDF documents and use their content in LLM prompts while
# maintaining document structure and formatting context.

class PDFTextExtractionAction < Sublayer::Actions::Base
  def initialize(pdf_path:, include_tables: true, preserve_formatting: true)
    @pdf_path = pdf_path
    @include_tables = include_tables
    @preserve_formatting = preserve_formatting
  end

  def call
    begin
      validate_file
      extract_content
    rescue PDF::Reader::MalformedPDFError => e
      error_message = "PDF parsing error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@pdf_path)
      raise StandardError, "PDF file not found at path: #{@pdf_path}"
    end

    unless File.extname(@pdf_path).downcase == '.pdf'
      raise StandardError, "File is not a PDF: #{@pdf_path}"
    end
  end

  def extract_content
    reader = PDF::Reader.new(@pdf_path)
    content = {
      metadata: extract_metadata(reader),
      pages: []
    }

    reader.pages.each_with_index do |page, index|
      page_content = {
        page_number: index + 1,
        text: extract_page_text(page),
        tables: @include_tables ? extract_tables(page) : [],
        formatting: @preserve_formatting ? extract_formatting(page) : {}
      }
      content[:pages] << page_content
    end

    Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@pdf_path}")
    content
  end

  def extract_metadata(reader)
    {
      title: reader.info[:Title],
      author: reader.info[:Author],
      creator: reader.info[:Creator],
      page_count: reader.page_count
    }
  end

  def extract_page_text(page)
    # Remove excessive whitespace while preserving paragraph structure
    page.text.gsub(/\s+/, ' ').gsub(/\n\s*\n/, "\n\n").strip
  end

  def extract_tables(page)
    tables = []
    # Basic table detection using regular expressions
    # This is a simplified approach - for more robust table extraction,
    # consider using specialized gems like 'tabula-rb'
    table_patterns = page.text.scan(/(?:\|.*\|\n)+/)
    
    table_patterns.each do |table_text|
      rows = table_text.split("\n").map { |row| row.split('|').map(&:strip) }
      tables << {
        headers: rows.first,
        data: rows[1..-1]
      } if rows.any? && rows.first.length > 1
    end
    tables
  end

  def extract_formatting(page)
    # Extract basic formatting information
    # This is a simplified version - actual implementation would depend on
    # specific PDF structure and requirements
    {
      font_sizes: page.fonts.keys,
      text_style: {
        bold: contains_bold?(page),
        italic: contains_italic?(page)
      }
    }
  end

  def contains_bold?(page)
    page.fonts.any? { |font, _| font.to_s.downcase.include?('bold') }
  end

  def contains_italic?(page)
    page.fonts.any? { |font, _| font.to_s.downcase.include?('italic') }
  end
end