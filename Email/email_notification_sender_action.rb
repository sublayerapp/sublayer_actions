# Description: Sublayer::Action responsible for sending email notifications using services like SendGrid or AWS SES.
# This action can be utilized to inform users about AI-driven updates or alerts.
#
# It is initialized with a from_address, to_address, subject, and body,
# and optionally a service configuration for SendGrid or AWS SES.
# It returns a response object containing the status of the email sending operation.
#
# Example usage: When you want to notify users via email about an important AI-driven insight or alert.

require 'aws-sdk-ses'
require 'sendgrid-ruby'
include SendGrid

class EmailNotificationSenderAction < Sublayer::Actions::Base
  def initialize(from_address:, to_address:, subject:, body:, service: :sendgrid, api_key: nil, region: 'us-east-1')
    @from_address = from_address
    @to_address = to_address
    @subject = subject
    @body = body
    @service = service
    @api_key = api_key || (service == :sendgrid ? ENV['SENDGRID_API_KEY'] : ENV['AWS_SES_API_KEY'])
    @region = region
  end

  def call
    case @service
    when :sendgrid
      send_via_sendgrid
    when :aws_ses
      send_via_aws_ses
    else
      raise ArgumentError, "Unsupported email service provided: \\#{@service}"
    end
  end

  private

  def send_via_sendgrid
    mail = Mail.new
    mail.from = Email.new(email: @from_address)
    mail.subject = @subject
    personalization = Personalization.new
    personalization.add_to(Email.new(email: @to_address))
    mail.add_personalization(personalization)
    mail.add_content(Content.new(type: 'text/plain', value: @body))

    sg = SendGrid::API.new(api_key: @api_key)
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully via SendGrid with status \\#{response.status_code}")
      response
    rescue StandardError => e
      error_message = "Error sending email via SendGrid: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def send_via_aws_ses
    ses = Aws::SES::Client.new(region: @region, credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']))
    begin
      response = ses.send_email({
        destination: {
          to_addresses: [@to_address]
        },
        message: {
          body: {
            text: {
              charset: 'UTF-8',
              data: @body
            }
          },
          subject: {
            charset: 'UTF-8',
            data: @subject
          }
        },
        source: @from_address
      })
      Sublayer.configuration.logger.log(:info, "Email sent successfully via AWS SES with message ID \\#{response.message_id}")
      response
    rescue Aws::SES::Errors::ServiceError => e
      error_message = "Error sending email via AWS SES: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
