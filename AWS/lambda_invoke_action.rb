require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking AWS Lambda functions.
# This action enables integration with AWS Lambda, allowing for serverless compute operations in AI-driven workflows.
#
# It is initialized with a function_name and payload, and it returns the response from the invoked function.
#
# Example usage: When you want to trigger a Lambda function as part of a larger AI workflow to process data or trigger another service.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: {})
    @function_name = function_name
    @payload = payload
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'], credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']))
  end

  def call
    begin
      response = @client.invoke({
        function_name: @function_name,
        payload: @payload.to_json
      })

      result = JSON.parse(response.payload.string)
      Sublayer.configuration.logger.log(:info, "Successfully invoked AWS Lambda function \#{@function_name}", result)

      result
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking AWS Lambda function \#{@function_name}: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
