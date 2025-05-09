require 'aws-sdk-lambda'

# Description: Sublayer::Action responsible for invoking an AWS Lambda function.
# This action allows easy integration with serverless architectures,
# enabling Sublayer workflows to trigger complex backend processes.
#
# Requires: 'aws-sdk-lambda' gem
# $ gem install aws-sdk-lambda
# Or add `gem 'aws-sdk-lambda'` to your Gemfile
#
# It is initialized with the function_name, payload (optional), and invocation_type (optional).
# It returns the response from the Lambda function invocation.
#
# Example usage: When you want to trigger a serverless process as part of your Sublayer workflow.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload: nil, invocation_type: 'RequestResponse')
    @function_name = function_name
    @payload = payload
    @invocation_type = invocation_type
    @client = Aws::Lambda::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      response = @client.invoke({
        function_name: @function_name,
        invocation_type: @invocation_type,
        payload: @payload.to_json
      })

      Sublayer.configuration.logger.log(:info, "Successfully invoked Lambda function: #{@function_name}")
      
      # Parse and return the response payload
      JSON.parse(response.payload.string)
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking Lambda function: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end