require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# which can be useful for automated notifications or sending AI-generated content to users.
#
# It is initialized with sender, recipient, subject, and body of the email.
# It returns true if the email was sent successfully, false otherwise.
#
# Example usage: When you want to send an email notification or AI-generated content to a user.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:)
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @smtp_server = ENV['SMTP_SERVER']
    @smtp_port = ENV['SMTP_PORT'].to_i
    @smtp_username = ENV['SMTP_USERNAME']
    @smtp_password = ENV['SMTP_PASSWORD']
  end

  def call
    begin
      message = compose_message
      send_email(message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end

  private

  def compose_message
    <<~MESSAGE
      From: #{@sender}
      To: #{@recipient}
      Subject: #{@subject}

      #{@body}
    MESSAGE
  end

  def send_email(message)
    Net::SMTP.start(@smtp_server, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
      smtp.send_message message, @sender, @recipient
    end
  end
end