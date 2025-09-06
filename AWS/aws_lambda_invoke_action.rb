require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking AWS Lambda functions to perform cloud-based operations.
# This action allows easy integration of AWS Lambda functionality into Sublayer workflows,
# enabling cloud-based computation and operations as part of AI-driven processes.
#
# It is initialized with a function_name and an optional payload.
# It returns the result returned from the invoked Lambda function.
#
# Example usage: When you want to trigger a cloud-based operation within AWS Lambda as part of a larger AI workflow.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: {})
    @function_name = function_name
    @payload = payload
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    begin
      response = invoke_lambda
      Sublayer.configuration.logger.log(:info, "Successfully invoked AWS Lambda function: #{@function_name}")
      response.payload.string
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking AWS Lambda function: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def invoke_lambda
    @client.invoke({
      function_name: @function_name,
      payload: JSON.generate(@payload),
      log_type: 'Tail'
    })
  end
end
