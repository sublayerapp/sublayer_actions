require 'prawn'

# Description: Sublayer::Action responsible for generating PDF documents from structured data or text.
# This action can be used to create reports, invoices, or other documents based on AI-generated content.
#
# Requires: 'prawn' gem
# $ gem install prawn
# Or add `gem 'prawn'` to your Gemfile
#
# It is initialized with a title, content (can be a string or an array of strings), and optional metadata.
# It returns the path to the generated PDF file.
#
# Example usage: When you want to create a PDF report or document based on AI-generated content.

class PDFGenerationAction < Sublayer::Actions::Base
  def initialize(title:, content:, output_path:, metadata: {})
    @title = title
    @content = content
    @output_path = output_path
    @metadata = metadata
  end

  def call
    begin
      generate_pdf
      Sublayer.configuration.logger.log(:info, "PDF generated successfully: #{@output_path}")
      @output_path
    rescue StandardError => e
      error_message = "Error generating PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_pdf
    Prawn::Document.generate(@output_path) do |pdf|
      # Set metadata
      pdf.info[:Title] = @title
      @metadata.each { |key, value| pdf.info[key] = value }

      # Add content
      pdf.text @title, size: 18, style: :bold
      pdf.move_down 20

      if @content.is_a?(Array)
        @content.each do |paragraph|
          pdf.text paragraph
          pdf.move_down 10
        end
      else
        pdf.text @content
      end

      # Add page numbers
      pdf.number_pages "Page <page> of <total>", at: [pdf.bounds.right - 150, 0]
    end
  end
end
