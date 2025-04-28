require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking AWS Lambda functions.
# This action allows Sublayer workflows to trigger serverless functions for complex processing or integrations.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with the function name, region, and optional payload.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to execute a serverless function as part of your Sublayer workflow,
# such as for data processing, third-party integrations, or any task that can benefit from AWS Lambda's capabilities.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, region:, payload: nil)
    @function_name = function_name
    @region = region
    @payload = payload
    @client = Aws::Lambda::Client.new(region: @region)
  end

  def call
    begin
      response = invoke_lambda
      Sublayer.configuration.logger.log(:info, "Successfully invoked Lambda function: #{@function_name}")
      response.payload.string
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking Lambda function: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def invoke_lambda
    params = {
      function_name: @function_name,
      invocation_type: 'RequestResponse'
    }
    params[:payload] = @payload.to_json if @payload

    @client.invoke(params)
  end
end
