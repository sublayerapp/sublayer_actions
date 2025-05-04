require 'prawn'

# Description: Sublayer::Action responsible for generating PDF documents from structured data.
# This action can be used to create reports or documents based on AI analysis or other structured data inputs.
#
# Requires: 'prawn' gem
# $ gem install prawn
# Or add `gem 'prawn'` to your Gemfile
#
# It is initialized with a title, content (an array of content blocks), and an optional output_path.
# If no output_path is provided, it returns the generated PDF as a string.
# If an output_path is provided, it saves the PDF to the specified path and returns the path.
#
# Example usage: When you want to generate a PDF report based on AI-generated insights or analysis.

class PDFGenerateAction < Sublayer::Actions::Base
  def initialize(title:, content:, output_path: nil)
    @title = title
    @content = content
    @output_path = output_path
  end

  def call
    begin
      pdf = generate_pdf
      if @output_path
        save_pdf(pdf)
        Sublayer.configuration.logger.log(:info, "PDF generated and saved to #{@output_path}")
        @output_path
      else
        Sublayer.configuration.logger.log(:info, "PDF generated successfully")
        pdf.render
      end
    rescue StandardError => e
      error_message = "Error generating PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_pdf
    Prawn::Document.new do |pdf|
      pdf.font_size(24) { pdf.text @title, align: :center }
      pdf.move_down 20

      @content.each do |block|
        case block[:type]
        when 'paragraph'
          pdf.text block[:text]
        when 'heading'
          pdf.move_down 10
          pdf.font_size(16) { pdf.text block[:text], style: :bold }
          pdf.move_down 5
        when 'list'
          pdf.move_down 10
          block[:items].each do |item|
            pdf.text "• #{item}"
          end
          pdf.move_down 5
        end
        pdf.move_down 10
      end
    end
  end

  def save_pdf(pdf)
    pdf.render_file(@output_path)
  end
end
