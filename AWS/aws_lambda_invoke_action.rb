require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking AWS Lambda functions.
# This action allows Sublayer workflows to trigger serverless functions for complex processing or integrations.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with a function_name, region, and optional payload.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless function as part of your AI workflow,
# such as for data processing, third-party API interactions, or any other complex operations.

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
      parse_response(response)
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

  def parse_response(response)
    if response.function_error
      error_message = "Lambda function returned an error: #{response.function_error}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    JSON.parse(response.payload.string)
  rescue JSON::ParserError => e
    Sublayer.configuration.logger.log(:warn, "Failed to parse Lambda response as JSON: #{e.message}")
    response.payload.string
  end
end
