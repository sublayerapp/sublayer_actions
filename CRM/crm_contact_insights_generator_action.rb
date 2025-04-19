# Description: Sublayer::Action responsible for generating insights or recommendations for CRM contacts.
# This action leverages AI to aid in sales strategies and customer engagement by analyzing CRM data and providing meaningful insights.
#
# It is initialized with contact details and optionally previous interaction data, and it returns a structured summary of insights.
#
# Example usage: When a sales representative wants to better understand a contact's needs and preferences based on past interactions and AI-driven insights.

class CRMContactInsightsGeneratorAction < Sublayer::Actions::Base
  def initialize(contact_details:, interaction_history: nil)
    @contact_details = contact_details
    @interaction_history = interaction_history
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      prompt = generate_prompt(@contact_details, @interaction_history)
      response = @client.completions(parameters: { prompt: prompt, max_tokens: 150 })

      insights = parse_response(response)
      Sublayer.configuration.logger.log(:info, "CRM contact insights generated successfully")

      insights
    rescue OpenAI::Error => e
      error_message = "Error generating CRM contact insights: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_prompt(contact_details, interaction_history)
    "Generate insights for the following contact based on past interactions:\nContact Details: #{contact_details}\nInteraction History: #{interaction_history || 'N/A'}"
  end

  def parse_response(response)
    response['choices'].first['text']
  end
end