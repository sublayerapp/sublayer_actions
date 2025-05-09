require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking AWS Lambda functions.
# This action allows Sublayer workflows to trigger serverless functions for
# additional processing or integration with other AWS services.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with a function_name and optional payload.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless function as part of your Sublayer workflow,
# such as for data processing, notifications, or integrating with other AWS services.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: nil, region: 'us-east-1')
    @function_name = function_name
    @payload = payload
    @region = region
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
