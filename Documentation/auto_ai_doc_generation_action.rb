# Description: Sublayer::Action responsible for generating documentation for a code repository using AI, 
# summarizing code structure, key functions, and potential pitfalls.
# This aims to keep documentation up-to-date effortlessly.
# 
# Requires: 'openai' gem for accessing AI models
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with a repo_path and returns a documentation summary.
#
# Example usage: Use this action to automatically generate and update documentation as part of your CI/CD pipeline.

require 'openai'
require 'logger'

class AutoAIDocGenerationAction < Sublayer::Actions::Base
  def initialize(repo_path:)
    @repo_path = repo_path
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    @logger = Logger.new(STDOUT)
  end

  def call
    begin
      code_summary = analyze_code_structure
      Sublayer.configuration.logger.log(:info, "Documentation generated successfully for #{@repo_path}")
      code_summary
    rescue OpenAI::Error => e
      error_message = "Error generating documentation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during documentation generation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def analyze_code_structure
    files_content = retrieve_files_content
    prompt = "Generate a documentation summary including code structure, key functions, and potential pitfalls.\n#{files_content}"
    response = @client.completions.create(engine: 'davinci-codex', prompt: prompt, max_tokens: 1000)
    response.choices.first.text.strip
  end

  def retrieve_files_content
    Dir.chdir(@repo_path) do
      `git ls-files`.split("\n").map do |file|
        next unless File.file?(file)
        "File: #{file}\n" + File.read(file)
      end.compact.join("\n---\n")
    end
  end
end
