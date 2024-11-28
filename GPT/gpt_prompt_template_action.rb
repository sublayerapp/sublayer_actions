require 'yaml'

# Description: Sublayer::Action responsible for managing and applying prompt templates for GPT models.
# This action takes a template name and variables as input, then returns a fully formatted prompt string
# ready for use with GPT models.
#
# It is initialized with a template_name and a hash of variables.
# It returns a formatted prompt string.
#
# Example usage: When you want to consistently format prompts for GPT models across different use cases in your application.

class GPTPromptTemplateAction < Sublayer::Actions::Base
  def initialize(template_name:, variables: {})
    @template_name = template_name
    @variables = variables
    @templates_path = File.join(Dir.pwd, 'config', 'gpt_templates.yml')
  end

  def call
    begin
      template = load_template
      formatted_prompt = format_template(template)
      Sublayer.configuration.logger.log(:info, "Successfully formatted prompt for template: #{@template_name}")
      formatted_prompt
    rescue StandardError => e
      error_message = "Error formatting GPT prompt template: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def load_template
    unless File.exist?(@templates_path)
      raise StandardError, "Templates file not found at #{@templates_path}"
    end

    templates = YAML.load_file(@templates_path)
    template = templates[@template_name]

    unless template
      raise StandardError, "Template '#{@template_name}' not found in templates file"
    end

    template
  end

  def format_template(template)
    @variables.each do |key, value|
      template = template.gsub("{#{key}}", value.to_s)
    end

    # Check if all placeholders have been replaced
    if template.match(/\{[^\}]+\}/)
      raise StandardError, "Not all placeholders in the template were replaced. Missing variables."
    end

    template
  end
end
