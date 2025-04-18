require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking an AWS Lambda function with specified parameters.
# This action provides flexibility in executing serverless functions in response to workflow triggers,
# enabling seamless integration with AWS Lambda services in your AI-driven workflows.
#
# It is initialized with the function_name and optional payload, and upon execution,
# it returns the response payload from the Lambda function.
#
# Example usage: When you want to invoke a serverless AWS Lambda function as part of a broader AI workflow.

class AWSLambdaInvocationAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: {})
    @function_name = function_name
    @payload = payload
    @client = Aws::Lambda::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      response = @client.invoke(
        function_name: @function_name,
        payload: @payload.to_json
      )
      return JSON.parse(response.payload.string)
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking AWS Lambda function: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::ParserError => e
      error_message = "Error parsing AWS Lambda response: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Unexpected error: #{e.message}")
      raise e
    end
  end
end