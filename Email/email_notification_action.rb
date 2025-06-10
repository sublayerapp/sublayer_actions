require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails through an SMTP server.
# This action allows for integration with SMTP to send emails with predefined templates,
# making it useful for sending notifications and updates as part of an automated workflow.
#
# It is initialized with smtp_settings (host, port, user, password),
# from_address, to_address, subject, and body_template.
# It returns a confirmation message upon successful sending.
#
# Example usage: When you want to send an email notification to a user based on AI-driven insights or other triggers.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, from_address:, to_address:, subject:, body_template:)
    @smtp_settings = smtp_settings
    @from_address = from_address
    @to_address = to_address
    @subject = subject
    @body_template = body_template
  end

  def call
    begin
      message = build_message
      send_email(message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_address}")
      "Email sent successfully."
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def build_message
    <<~MESSAGE
      From: #{@from_address}
      To: #{@to_address}
      Subject: #{@subject}

      #{@body_template}
    MESSAGE
  end

  def send_email(message)
    Net::SMTP.start(
      @smtp_settings[:host],
      @smtp_settings[:port],
      @smtp_settings[:user],
      @smtp_settings[:password],
      :plain
    ) do |smtp|
      smtp.send_message message, @from_address, @to_address
    end
  end
end
