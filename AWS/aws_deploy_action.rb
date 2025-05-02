# AWSDeployAction
# This Sublayer::Action is responsible for deploying applications to AWS using a declarative input structure.
# It can deploy resources such as EC2 instances, S3 buckets, and more, following a generated deployment plan.
#
# Requirements:
#   - 'aws-sdk' gem
#   - Set up AWS credentials in your environment

require 'aws-sdk'

class AWSDeployAction < Sublayer::Actions::Base
  def initialize(deployment_plan:, region: 'us-east-1')
    @deployment_plan = deployment_plan
    @region = region
    @client = Aws::CloudFormation::Client.new(region: @region)
  end

  def call
    begin
      stack_name = @deployment_plan[:stack_name]
      template_body = @deployment_plan[:template_body]
      parameters = format_parameters(@deployment_plan[:parameters])
      deployment_options = {
        stack_name: stack_name,
        template_body: template_body,
        parameters: parameters,
        capabilities: ['CAPABILITY_NAMED_IAM']
      }
      
      if stack_exists?(stack_name)
        update_stack(deployment_options)
      else
        create_stack(deployment_options)
      end
      Sublayer.configuration.logger.log(:info, "Deployment initiated for stack: #{stack_name}")
    rescue Aws::CloudFormation::Errors::ServiceError => e
      error_message = "Error deploying stack: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def stack_exists?(stack_name)
    stacks = @client.describe_stacks(stack_name: stack_name).stacks
    stacks.any? { |stack| stack.stack_name == stack_name }
  rescue Aws::CloudFormation::Errors::ValidationError
    false
  end

  def create_stack(options)
    @client.create_stack(options)
  end

  def update_stack(options)
    @client.update_stack(options)
  rescue Aws::CloudFormation::Errors::ValidationError => e
    raise unless e.message.include?('No updates are to be performed.')
    Sublayer.configuration.logger.log(:info, "No updates were necessary for stack: #{options[:stack_name]}")
  end

  def format_parameters(parameters)
    parameters.map do |key, value|
      { parameter_key: key, parameter_value: value }
    end
  end
end