require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking AWS Lambda functions.
# This action allows Sublayer workflows to trigger serverless functions for complex processing or integrations.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with a function_name and optional payload.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless function as part of your Sublayer workflow,
# such as for data processing, third-party API interactions, or any other complex operations.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: nil, region: ENV['AWS_REGION'])
    @function_name = function_name
    @payload = payload
    @client = Aws::Lambda::Client.new(region: region)
  end

  def call
    begin
      response = @client.invoke({
        function_name: @function_name,
        payload: @payload.to_json
      })

      if response.function_error
        error_message = "Lambda function execution failed: #{response.function_error}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      result = JSON.parse(response.payload.string)
      Sublayer.configuration.logger.log(:info, "Successfully invoked Lambda function: #{@function_name}")
      result
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking Lambda function: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end