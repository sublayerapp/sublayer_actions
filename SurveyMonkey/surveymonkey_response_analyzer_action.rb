require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for analyzing and summarizing recent responses from a specific SurveyMonkey survey.
# This action fetches data from SurveyMonkey using their API and processes it to generate quick insights and summaries.
#
# Requires: SurveyMonkey API access
#
# Example usage: When you want to gain insights from recent survey data quickly for reporting or decision-making purposes.

class SurveyMonkeyResponseAnalyzerAction < Sublayer::Actions::Base
  def initialize(survey_id:, token:, summary_type: 'quick_summary')
    @survey_id = survey_id
    @token = token
    @summary_type = summary_type
    @api_url = "https://api.surveymonkey.com/v3/surveys/#{@survey_id}/responses/bulk"
  end

  def call
    responses = fetch_survey_responses
    analyze_responses(responses)
  rescue StandardError => e
    log_error("Error analyzing SurveyMonkey responses: #{e.message}")
    raise e
  end

  private

  def fetch_survey_responses
    uri = URI.parse(@api_url)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.code.to_i.between?(200, 299)
      JSON.parse(response.body)["data"]
    else
      error_message = "Failed to fetch survey responses: HTTP #{response.code} - #{response.message}"
      log_error(error_message)
      raise StandardError, error_message
    end
  end

  def analyze_responses(responses)
    # Basic analysis logic depending on @summary_type
    case @summary_type
    when 'quick_summary'
      quick_summary(responses)
    else
      raise StandardError, "Unknown summary type: #{@summary_type}"
    end
  end

  def quick_summary(responses)
    # Placeholder for simple summarization logic
    # Implement specific analysis logic according to your needs
    summaries = responses.map { |response| "Response ID: #{response['id']} - Summary Info" }
    Sublayer.configuration.logger.log(:info, "Generated quick summary for SurveyMonkey responses")
    summaries
  end

  def log_error(message)
    Sublayer.configuration.logger.log(:error, message)
  end
end
