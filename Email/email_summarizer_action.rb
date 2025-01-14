# Description: Sublayer::Action responsible for summarizing incoming emails.
# This action extracts key points and identifies action items from email content.
#
# Example usage: When you want to quickly understand the gist of emails and highlight action items for better productivity.

require 'mail'
require 'openai'

class EmailSummarizerAction < Sublayer::Actions::Base
  def initialize(email_content:, openai_api_key: ENV['OPENAI_API_KEY'])
    @openai_api_key = openai_api_key
    @client = OpenAI::Client.new(access_token: @openai_api_key)
    @mailer = Mail.new(email_content)
  end

  def call
    begin
      summary = generate_summary
      Sublayer.configuration.logger.log(:info, "Email summarized successfully")
      summary
    rescue OpenAI::Error => e
      error_message = "Error generating email summary: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error in email summarization: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_summary
    prompt = "Summarize this email and list any action items: \n
"
    prompt += @mailer.decoded

    response = @client.completions(parameters: {
      model: "text-davinci-003",
      prompt: prompt,
      max_tokens: 150
    })

    response.choices.dig(0, 'text').strip
  end
end
