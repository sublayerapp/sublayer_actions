require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking an AWS Lambda function.
# This action allows easy integration with serverless architectures and cloud-based processes.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with a function_name and payload.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless process or integrate with AWS Lambda
# as part of your Sublayer workflow.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload:, region: 'us-east-1')
    @function_name = function_name
    @payload = payload
    @region = region
    @client = Aws::Lambda::Client.new(region: @region)
  end

  def call
    begin
      response = @client.invoke({
        function_name: @function_name,
        payload: @payload.to_json
      })

      if response.function_error
        error_message = "Lambda function invocation error: #{response.function_error}"
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
    rescue JSON::ParserError => e
      error_message = "Error parsing Lambda function response: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end