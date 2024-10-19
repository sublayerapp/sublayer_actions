require 'prawn'

# Description: Sublayer::Action responsible for generating PDF documents from structured data or text.
# This action can be used to create reports, invoices, or other documents based on AI-generated content.
#
# Requires: 'prawn' gem
# $ gem install prawn
# Or add `gem 'prawn'` to your Gemfile
#
# It is initialized with content (array of paragraphs or hash of key-value pairs) and optional title.
# It returns the path to the generated PDF file.
#
# Example usage: When you want to create a PDF report or document based on AI-generated content.

class PDFGenerateAction < Sublayer::Actions::Base
  def initialize(content:, title: nil, output_path: nil)
    @content = content
    @title = title
    @output_path = output_path || generate_output_path
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
      pdf.font('Helvetica')
      
      if @title
        pdf.text @title, size: 18, style: :bold, align: :center
        pdf.move_down 20
      end

      if @content.is_a?(Array)
        @content.each do |paragraph|
          pdf.text paragraph
          pdf.move_down 10
        end
      elsif @content.is_a?(Hash)
        @content.each do |key, value|
          pdf.text "#{key}: #{value}", style: :bold
          pdf.move_down 5
        end
      else
        pdf.text @content.to_s
      end
    end
  end

  def generate_output_path
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    File.join(Dir.tmpdir, "generated_pdf_#{timestamp}.pdf")
  end
end