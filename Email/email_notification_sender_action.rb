require 'sendgrid-ruby'
require 'aws-sdk-ses'

# Description: Sublayer::Action responsible for sending email notifications using providers like SendGrid or AWS SES.
# This action can be used to notify users based on AI-generated insights or actions.
#
# It is initialized with the required parameters to send an email, including the provider,
# email details, and optional configuration for the provider.
#
# Example usage: When you want to send an email notification based on insights generated
# by an AI process.

class EmailNotificationSenderAction < Sublayer::Actions::Base
  def initialize(provider:, from:, to:, subject:, content:, provider_config: {})
    @provider = provider.downcase.to_sym
    @from = from
    @to = to
    @subject = subject
    @content = content
    @provider_config = provider_config
  end

  def call
    case @provider
    when :sendgrid
      send_via_sendgrid
    when :aws_ses
      send_via_aws_ses
    else
      raise ArgumentError, "Unsupported email provider: #{@provider}"
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error sending email notification: #{e.message}")
    raise e
  end

  private

  def send_via_sendgrid
    client = SendGrid::API.new(api_key: @provider_config[:api_key])
    mail = SendGrid::Mail.new(
      from: SendGrid::Email.new(email: @from),
      to: SendGrid::Email.new(email: @to),
      subject: @subject,
      content: SendGrid::Content.new(type: 'text/plain', value: @content)
    )

    response = client.client.mail._('send').post(request_body: mail.to_json)

    unless response.status_code.to_i.between?(200, 299)
      raise "SendGrid API error: HTTP #{response.status_code} - #{response.body}"
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully via SendGrid to #{@to}")
  end

  def send_via_aws_ses
    client = Aws::SES::Client.new(@provider_config)

    response = client.send_email(
      destination: {
        to_addresses: [@to],
      },
      message: {
        body: {
          text: {
            charset: "UTF-8",
            data: @content,
          },
        },
        subject: {
          charset: "UTF-8",
          data: @subject,
        },
      },
      source: @from
    )

    Sublayer.configuration.logger.log(:info, "Email sent successfully via AWS SES to #{@to}")
    response
  rescue Aws::SES::Errors::ServiceError => e
    error_message = "AWS SES API error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end