require 'aws-sdk-lambda'

# Description: Sublayer::Action that invokes an AWS Lambda function with a specified payload and returns the response.
#
# Initialized with a function_name and payload; it uses AWS SDK to invoke the specified Lambda function with the given payload.
# Returns the response from the Lambda function.
#
# Example usage: Useful for triggering serverless functions and integrating their outputs into Sublayer workflows.

class AWSLambdaInvokeAction < Sublayer::Actions::Base
  def initialize(function_name:, payload:)
    @function_name = function_name
    @payload = payload.to_json
    @client = Aws::Lambda::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      response = @client.invoke({
        function_name: @function_name,
        payload: @payload
      })

      response_payload = JSON.parse(response.payload.string)
      Sublayer.configuration.logger.log(:info, "Invoked Lambda function #{@function_name} successfully")

      response_payload
    rescue Aws::Lambda::Errors::ServiceError => e
      error_message = "Error invoking Lambda function: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
