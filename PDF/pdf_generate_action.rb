require 'prawn'

# Description: Sublayer::Action responsible for generating PDF documents from structured data or HTML.
# This action allows for easy creation of reports, invoices, or other documents based on AI-generated content.
#
# Requires: 'prawn' gem
# $ gem install prawn
# Or add `gem 'prawn'` to your Gemfile
#
# It is initialized with content (either a string of HTML or a hash of structured data) and an output file path.
# It returns the path to the generated PDF file.
#
# Example usage: When you want to create a PDF report or document based on AI-generated content.

class PDFGenerateAction < Sublayer::Actions::Base
  def initialize(content:, output_path:, options: {})
    @content = content
    @output_path = output_path
    @options = options
  end

  def call
    begin
      generate_pdf
      Sublayer.configuration.logger.log(:info, "PDF generated successfully at #{@output_path}")
      @output_path
    rescue StandardError => e
      error_message = "Error generating PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_pdf
    Prawn::Document.generate(@output_path, @options) do |pdf|
      if @content.is_a?(Hash)
        generate_from_structured_data(pdf)
      else
        generate_from_html(pdf)
      end
    end
  end

  def generate_from_structured_data(pdf)
    @content.each do |key, value|
      pdf.text "#{key}: #{value}"
      pdf.move_down 10
    end
  end

  def generate_from_html(pdf)
    # Note: This is a simplified HTML to PDF conversion.
    # For more complex HTML, consider using a dedicated HTML to PDF library.
    @content.split("<br>").each do |line|
      pdf.text line.gsub(/</?[^>]*>/, "")
      pdf.move_down 5
    end
  end
end
