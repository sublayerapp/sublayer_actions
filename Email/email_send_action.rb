require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action allows for sending notifications or alerts from AI processes to users or administrators.
#
# It is initialized with smtp_settings, email details like from, to, subject, body.
# It sends the email and returns a success message upon successful execution.
#
# Example usage: When you want to notify an administrator about an AI-driven alert or insight.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, from:, to:, subject:, body:)
    @smtp_settings = smtp_settings
    @from = from
    @to = to
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address],
                   @smtp_settings[:port],
                   @smtp_settings[:domain],
                   @smtp_settings[:user_name],
                   @smtp_settings[:password],
                   @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @from, @to
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    "Email sent successfully"
  end
end
