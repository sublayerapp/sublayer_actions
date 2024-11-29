require 'prawn'
require 'redcarpet'
require 'nokogiri'

# Description: Sublayer::Action responsible for generating PDF documents from HTML or Markdown content.
# This action is useful for creating reports or documentation from AI-generated content.
#
# It is initialized with the content to be converted (either HTML or Markdown) and the output file path.
# It returns the path of the generated PDF file.
#
# Example usage: When you want to create a PDF report from AI-generated content in your Sublayer workflow.

class PDFGenerateAction < Sublayer::Actions::Base
  def initialize(content:, output_path:, content_type: :markdown)
    @content = content
    @output_path = output_path
    @content_type = content_type
  end

  def call
    begin
      case @content_type
      when :markdown
        html = markdown_to_html(@content)
        generate_pdf_from_html(html)
      when :html
        generate_pdf_from_html(@content)
      else
        raise ArgumentError, "Invalid content type. Expected :markdown or :html"
      end

      Sublayer.configuration.logger.log(:info, "PDF generated successfully at #{@output_path}")
      @output_path
    rescue StandardError => e
      error_message = "Error generating PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def markdown_to_html(markdown)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer)
    markdown.render(markdown)
  end

  def generate_pdf_from_html(html)
    doc = Nokogiri::HTML(html)
    
    Prawn::Document.generate(@output_path) do |pdf|
      doc.css('h1, h2, h3, h4, h5, h6, p, ul, ol').each do |element|
        case element.name
        when 'h1'
          pdf.text element.text, size: 24, style: :bold
        when 'h2'
          pdf.text element.text, size: 20, style: :bold
        when 'h3'
          pdf.text element.text, size: 16, style: :bold
        when 'h4', 'h5', 'h6'
          pdf.text element.text, size: 14, style: :bold
        when 'p'
          pdf.text element.text, size: 12
        when 'ul', 'ol'
          pdf.move_down 10
          element.css('li').each do |li|
            pdf.text "• #{li.text}", size: 12
          end
          pdf.move_down 10
        end
      end
    end
  end
end
