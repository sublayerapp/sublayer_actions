# Description: Sublayer::Action responsible for sending emails via SMTP.
# This action allows for sending email notifications or updates from AI-driven processes.
#
# It is initialized with required parameters like sender, recipient, subject, and body.
# Optional parameters include SMTP server details, credentials, and attachments.
# It returns true if the email was sent successfully, otherwise raises an exception.
#
# Example usage: When you want to send a notification or update from an AI process via email.

class SendEmailAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:, smtp_server: 'smtp.gmail.com', port: 587, username: nil, password: nil, attachments: [])
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @smtp_server = smtp_server
    @port = port
    @username = username || ENV['SMTP_USERNAME']
    @password = password || ENV['SMTP_PASSWORD']
    @attachments = attachments
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      true
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def send_email
    msg = Mail.new do
      from    @sender
      to      @recipient
      subject @subject
      body    @body
    end

    @attachments.each do |attachment|
      msg.add_file(attachment)
    end

    smtp = Net::SMTP.new(@smtp_server, @port)
    smtp.enable_starttls
    smtp.start(@smtp_server, @username, @password, :plain) do |smtp_connection|
      smtp_connection.send_message(msg.to_s, @sender, @recipient)
    end
  end
end