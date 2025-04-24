require 'mail'

# Description: Sublayer::Action responsible for sending emails through a specified provider (e.g., SMTP, SendGrid).
# This action can be used for notifications, alerts, or sending generated content via email.
#
# It is initialized with the following parameters:
# - from: The sender's email address
# - to: The recipient's email address
# - subject: The email subject
# - body: The email body
# - provider: The email provider ('smtp' or 'sendgrid')
# - smtp_settings (optional): A hash containing SMTP settings (host, port, user, password, domain, authentication, enable_starttls_auto)
# - sendgrid_api_key: SendGrid API key
#
# Example usage: Sending notifications or generated content via email within a Sublayer workflow.
class SendEmailAction < Sublayer::Actions::Base
  def initialize(from:, to:, subject:, body:, provider:, smtp_settings: {}, sendgrid_api_key: nil)
    @from = from
    @to = to
    @subject = subject
    @body = body
    @provider = provider
    @smtp_settings = smtp_settings
    @sendgrid_api_key = sendgrid_api_key
  end

  def call
    begin
      mail = Mail.new do
        from @from
        to @to
        subject @subject
        body @body
      end

      case @provider
      when 'smtp'
        send_via_smtp(mail)
      when 'sendgrid'
        send_via_sendgrid(mail)
      else
        raise ArgumentError, "Invalid email provider: #{@provider}"
      end

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def send_via_smtp(mail)
    mail.delivery_method :smtp, @smtp_settings
    mail.deliver
  end

  def send_via_sendgrid(mail)
    raise ArgumentError, "SendGrid API key is required" if @sendgrid_api_key.nil?

    Mail.register_interceptor(SendGrid::MailInterceptor.new(@sendgrid_api_key))
    mail.deliver
  end
end