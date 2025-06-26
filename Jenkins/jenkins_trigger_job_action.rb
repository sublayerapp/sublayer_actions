require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Jenkins job with specified parameters.
# This action allows integration with Jenkins, a popular CI/CD tool, by triggering jobs to automate workflows.
#
# It is initialized with a jenkins_url, job_name, and optionally, parameters for the job.
# It returns the queue item ID to confirm the job was triggered.
#
# Example usage: When you want to automate CI/CD workflows by triggering Jenkins jobs based on AI-generated insights or project events.

class JenkinsTriggerJobAction < Sublayer::Actions::Base
  def initialize(jenkins_url:, job_name:, parameters: {}, username: nil, api_token: nil)
    @jenkins_url = jenkins_url
    @job_name = job_name
    @parameters = parameters
    @username = username
    @api_token = api_token
  end

  def call
    trigger_jenkins_job
  rescue StandardError => e
    error_message = "Error triggering Jenkins job: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def trigger_jenkins_job
    uri = URI.parse(File.join(@jenkins_url, "job/#{@job_name}/buildWithParameters"))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth(@username, @api_token) if @username && @api_token

    request.set_form_data(@parameters) if @parameters.any?

    response = http.request(request)
    case response
    when Net::HTTPSuccess
      queue_id = JSON.parse(response.body)["queueId"]
      Sublayer.configuration.logger.log(:info, "Jenkins job triggered successfully. Queue ID: #{queue_id}")
      queue_id
    else
      error_message = "Failed to trigger Jenkins job: HTTP \
#{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
