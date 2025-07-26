require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for triggering an AWS Lambda function with specific payloads.
# This action allows integration with AWS Lambda, enabling cloud functions to be invoked from Sublayer workflows.
#
# It is initialized with a function_name and payload. It returns the response from the Lambda function.
#
# Example usage: When you need to trigger AWS Lambda functions to execute serverless tasks based on AI workflows.

class AwsLambdaTriggerAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: {}, region: 'us-east-1', **kwargs)
    super(**kwargs)
    @function_name = function_name
    @payload = payload.to_json
    @client = Aws::Lambda::Client.new(region: region, credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']))
  end

  def call
    begin
      response = @client.invoke({
        function_name: @function_name,
        payload: @payload
      })
      handle_response(response)
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking AWS Lambda function: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def handle_response(response)
    if response.successful?
      response_payload = JSON.parse(response.payload.string)
      Sublayer.configuration.logger.log(:info, "Successfully invoked Lambda function \\#{@function_name}: \\#{response_payload}")
      response_payload
    else
      error_message = "Failed to invoke Lambda function: HTTP \\#{response.status_code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
