require 'openai'

# Description: Sublayer::Action responsible for analyzing audio transcriptions using GPT models.
# This action takes a transcription text and analyzes it to extract key information such as
# action items, summary points, and sentiment analysis using specific GPT prompts.
#
# It is initialized with transcription text and optional parameters for customizing the analysis.
# It returns a structured hash containing the analysis results.
#
# Example usage: When you want to automatically process meeting recordings or voice notes
# to extract actionable insights and summaries for further use in AI workflows.

class GPTTranscriptionAnalysisAction < Sublayer::Actions::Base
  DEFAULT_PROMPT_TEMPLATE = <<~PROMPT
    Analyze the following transcription and extract:
    1. Key action items (as a list)
    2. Brief summary (2-3 sentences)
    3. Overall sentiment (positive, negative, or neutral)
    4. Main participants/speakers
    5. Key decisions made

    Transcription:
    {transcription}

    Please format your response as a JSON object with the following keys:
    action_items, summary, sentiment, participants, decisions
  PROMPT

  def initialize(transcription:, model: 'gpt-4', prompt_template: nil, temperature: 0.7)
    @transcription = transcription
    @model = model
    @prompt_template = prompt_template || DEFAULT_PROMPT_TEMPLATE
    @temperature = temperature
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_input
      response = analyze_transcription
      parsed_response = parse_response(response)
      
      Sublayer.configuration.logger.log(:info, 'Successfully analyzed transcription')
      parsed_response
    rescue JSON::ParserError => e
      error_message = 'Failed to parse GPT response as JSON'
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error analyzing transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_input
    raise ArgumentError, 'Transcription cannot be empty' if @transcription.to_s.strip.empty?
  end

  def analyze_transcription
    prompt = @prompt_template.gsub('{transcription}', @transcription)

    response = @client.chat(
      parameters: {
        model: @model,
        messages: [{ role: 'user', content: prompt }],
        temperature: @temperature
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  def parse_response(response)
    parsed = JSON.parse(response)
    {
      action_items: parsed['action_items'] || [],
      summary: parsed['summary'] || '',
      sentiment: parsed['sentiment'] || 'neutral',
      participants: parsed['participants'] || [],
      decisions: parsed['decisions'] || []
    }
  end
end