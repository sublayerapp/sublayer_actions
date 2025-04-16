# Description: Sublayer::Action responsible for analyzing the content of an email and generating a concise summary.
# This action is ideal for managing communications and prioritizing responses based on summarized content.
#
# It is initialized with email_content and returns a summary of the content.
#
# Example usage: When you want to quickly understand the key points of an email without reading the entire content.

class EmailContentSummaryAction < Sublayer::Actions::Base
  require 'openai'

  def initialize(email_content:)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    @email_content = email_content
  end

  def call
    summarize_email
  rescue OpenAI::Error => e
    error_message = "Error generating email summary: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def summarize_email
    response = @client.completions(engine: 'text-davinci-003', parameters: {
      prompt: "Summarize the following email content: \n#{@email_content}\n",
      max_tokens: 150,
      n: 1,
      stop: ['\n'],
      temperature: 0.5
    })

    summary = response['choices'][0]['text'].strip
    Sublayer.configuration.logger.log(:info, "Email summary generated successfully")
    summary
  end
end
