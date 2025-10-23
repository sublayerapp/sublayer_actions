require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking an AWS Lambda function.
# This action enables the use of AWS's serverless compute service to execute functions
# in response to events in a Sublayer workflow.
#
# It is initialized with a function_name and an optional payload to pass to the Lambda function.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless function to handle background tasks or execute microservices automatically.

class AwsLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: '{}')
    @function_name = function_name
    @payload = payload
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'],
                                      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    invoke_lambda
  rescue Aws::Lambda::Errors::ServiceError => e
    error_message = "AWS Lambda invocation error: #{e.message}"
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
      payload: @payload
    })

    if response.successful?
      Sublayer.configuration.logger.log(:info, "AWS Lambda function #{@function_name} invoked successfully")
      response.payload.string
    else
      error_message = "Failed to invoke Lambda function: HTTP #{response.status_code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
