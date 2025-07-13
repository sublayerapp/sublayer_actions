require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for triggering AWS Lambda functions with specific payloads.
# This action can be used to integrate AWS Lambda invocation within Sublayer workflows,
# enabling automated serverless function execution based on AI-driven triggers.
#
# It is initialized with function_name and payload (as a JSON-serializable hash).
# It returns the result of the Lambda function invocation.
#
# Example usage: When you want to trigger an AWS Lambda function with specific data
# as part of a Sublayer workflow's automated process.

class AWSLambdaFunctionTriggerAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: {})
    @function_name = function_name
    @payload = payload
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'], credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']))
  end

  def call
    invoke_lambda_function
  rescue Aws::Lambda::Errors::ServiceError => e
    error_message = "Error invoking AWS Lambda function: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def invoke_lambda_function
    response = @client.invoke({
      function_name: @function_name,
      payload: @payload.to_json
    })

    result_payload = JSON.parse(response.payload.string)
    Sublayer.configuration.logger.log(:info, "Lambda function #{@function_name} invoked successfully with result: #{result_payload}")
    result_payload
  end
end
