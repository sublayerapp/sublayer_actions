require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking an AWS Lambda function with specified payload and configuration.
# This action allows integrating AWS Lambda into Sublayer workflows, useful for serverless backend triggers or processing.
#
# It is initialized with the function name, payload, and optional configuration such as invocation type.
# It returns the response payload from the Lambda function.
#
# Example usage: When you want to trigger a serverless function in AWS as part of a larger AI-driven workflow.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload:, invocation_type: 'RequestResponse', client_context: nil)
    @function_name = function_name
    @payload = payload
    @invocation_type = invocation_type
    @client_context = client_context
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    invoke_lambda
  rescue Aws::Lambda::Errors::ServiceError => e
    error_message = "Error invoking AWS Lambda function: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error invoking AWS Lambda: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def invoke_lambda
    response = @client.invoke({
      function_name: @function_name,
      invocation_type: @invocation_type,
      log_type: 'None',
      payload: @payload.to_json,
      client_context: @client_context,
    })

    if response.successful?
      Sublayer.configuration.logger.log(:info, "Successfully invoked AWS Lambda #{@function_name}")
      JSON.parse(response.payload.string)
    else
      error_message = "Lambda invocation failed with status code: #{response.status_code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
