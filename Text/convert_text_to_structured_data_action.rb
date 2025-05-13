require 'json'
require 'yaml'

# Description: Sublayer::Action responsible for converting unstructured text into a structured format (JSON or YAML)
# based on a provided schema. This allows for easier parsing and utilization of the data in AI workflows.
#
# It is initialized with the text to convert, the desired output format (JSON or YAML), and a schema (optional).
# The schema can be used to guide the conversion process and ensure the output is in the correct format.
#
# Example usage: When you have extracted text from a website or file and want to convert it into a structured format
# for further processing by an AI model.

class ConvertTextToStructuredDataAction < Sublayer::Actions::Base
  def initialize(text:, output_format:, schema: nil)
    @text = text
    @output_format = output_format.downcase
    @schema = schema

    unless %w[json yaml].include?(@output_format)
      raise ArgumentError, "Invalid output format. Must be 'json' or 'yaml'."
    end
  end

  def call
    begin
      structured_data = convert_text
      Sublayer.configuration.logger.log(:info, "Successfully converted text to #{@output_format}")
      structured_data
    rescue StandardError => e
      error_message = "Error converting text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def convert_text
    # Placeholder for actual conversion logic.
    # This is where you would use an LLM or other parsing techniques,
    # potentially guided by the schema, to convert the unstructured text.
    # The example below performs a trivial conversion assuming the text *is* valid json

    # Example using JSON (assuming the text is JSON-formatted)
    if @output_format == 'json'
      begin
        return JSON.parse(@text)
      rescue JSON::ParserError => e
        raise StandardError, "Invalid JSON format: #{e.message}"
      end
    end

    # Example using YAML (assuming the text is YAML-formatted)
    if @output_format == 'yaml'
      begin
        return YAML.safe_load(@text)
      rescue Psych::SyntaxError => e
        raise StandardError, "Invalid YAML format: #{e.message}"
      end
    end

  end
end