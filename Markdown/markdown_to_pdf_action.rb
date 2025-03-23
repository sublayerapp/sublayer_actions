require 'pdfkit'

# Description: Sublayer::Action responsible for converting a Markdown document into a formatted PDF file.
# It uses the PDFKit library to perform the conversion, making it easy to share or archive documents
# created within the system.
#
# It is initialized with a markdown_content, and a target_file_path for the output PDF.
# It writes the PDF to the specified path and returns the path for confirmation.
#
# Example usage: When you want to convert markdown content into a PDF for distribution or archiving.

class MarkdownToPDFAction < Sublayer::Actions::Base
  def initialize(markdown_content:, target_file_path:)
    @markdown_content = markdown_content
    @target_file_path = target_file_path
  end

  def call
    begin
      generate_pdf
      Sublayer.configuration.logger.log(:info, "PDF generated successfully at #{@target_file_path}")
      @target_file_path
    rescue StandardError => e
      error_message = "Error generating PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_pdf
    pdfkit = PDFKit.new(@markdown_content, page_size: 'Letter')
    pdfkit.to_file(@target_file_path)
  end
end
