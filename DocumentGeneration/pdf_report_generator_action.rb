require 'prawn'

# Description: Sublayer::Action responsible for generating a PDF report from structured data or analysis results.
# This action allows for the creation of standalone documents from AI-driven insights by converting structured data into a formatted PDF.
#
# It is initialized with a title, author, and content (provided as structured data or raw text).
# It returns the path to the generated PDF file.
#
# Example usage: When you need to generate a report of the results from AI analysis or insights that can be shared or archived.

class PDFReportGeneratorAction < Sublayer::Actions::Base
  def initialize(title:, author:, content:, output_path: 'report.pdf')
    @title = title
    @author = author
    @content = content
    @output_path = output_path
  end

  def call
    begin
      generate_pdf
      Sublayer.configuration.logger.log(:info, "PDF report generated successfully at #{@output_path}")
      @output_path
    rescue StandardError => e
      error_message = "Error generating PDF report: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_pdf
    Prawn::Document.generate(@output_path) do
      text "Title: #{@title}", size: 20, style: :bold
      move_down 10
      text "Author: #{@author}", size: 15, style: :italic
      move_down 20
      text @content
    end
  end
end
