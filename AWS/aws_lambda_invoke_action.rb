require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking an AWS Lambda function with provided parameters.
# This action allows Sublayer workflows to trigger serverless functions for complex processing or integrations.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with the function_name and optional payload, region, and invocation_type.
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless function as part of your Sublayer workflow,
# such as for data processing, third-party integrations, or any task that benefits from Lambda's scalability.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: nil, region: 'us-east-1', invocation_type: 'RequestResponse')
    @function_name = function_name
    @payload = payload
    @region = region
    @invocation_type = invocation_type
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
      invocation_type: @invocation_type
    }
    params[:payload] = @payload.to_json if @payload

    @client.invoke(params)
  end

  def parse_response(response)
    case @invocation_type
    when 'RequestResponse'
      JSON.parse(response.payload.string)
    when 'Event'
      { status: 'Success', message: 'Lambda function invoked asynchronously' }
    when 'DryRun'
      { status: 'Success', message: 'Lambda function invocation configuration is valid' }
    else
      { status: 'Unknown', message: 'Unexpected invocation type' }
    end
  end
end
