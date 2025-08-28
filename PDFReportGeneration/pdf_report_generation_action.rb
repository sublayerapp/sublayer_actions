require 'prawn'
require 'prawn/table'

# Description: Sublayer::Action responsible for generating PDF reports from data.
# This action allows the creation of PDF reports, potentially including charts and graphs.
# Useful for creating summaries of Sublayer test results or other analytics.
#
# Requires: 'prawn' gem and 'prawn-table'
# $ gem install prawn prawn-table
# Or add `gem 'prawn', 'prawn-table'` to your Gemfile
#
# It is initialized with a title, data (array of hashes or a matrix for tables), and optionally, headers.
# On successful execution, it writes the PDF report to the specified file_path.
#
# Example usage: When you need to create a formatted PDF report from analytics data for sharing results internally or with clients.

class PDFReportGenerationAction < Sublayer::Actions::Base
  def initialize(file_path:, title:, data:, headers: nil)
    @file_path = file_path
    @title = title
    @data = data
    @headers = headers
  end

  def call
    generate_pdf_report
  rescue Prawn::Errors::PrawnError => e
    error_message = "Error generating PDF report: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def generate_pdf_report
    Prawn::Document.generate(@file_path) do |pdf|
      pdf.text @title, size: 24, style: :bold, align: :center
      pdf.move_down 20

      unless @headers.nil? || @data.empty?
        data_with_headers = [@headers] + @data
        pdf.table(data_with_headers, header: true) do |table|
          table.row(0).font_style = :bold
          table.position = :center
        end
      else
        pdf.text "No data available to display."
      end
    end
    Sublayer.configuration.logger.log(:info, "PDF report generated successfully at #{@file_path}")
  end
end
