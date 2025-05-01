# Description: Sublayer::Action responsible for sending emails via SMTP.
# This action enables Sublayer agents to provide email notifications or updates based on AI actions.
#
# It is initialized with the following parameters:
# - to: Recipient's email address
# - from: Sender's email address
# - subject: Email subject
# - body: Email body
# - smtp_settings: A hash containing SMTP settings (server, port, domain, user, password, authentication, enable_starttls_auto)
#
# Example usage: When you want to send an email notification based on an AI-generated insight.

require 'net/smtp'

class SendEmailAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, body:, smtp_settings: {})
    @to = to
    @from = from
    @subject = subject
    @body = body
    @smtp_settings = smtp_settings.reverse_merge(
      server: ENV['SMTP_SERVER'],
      port: ENV.fetch('SMTP_PORT', 587),
      domain: ENV['SMTP_DOMAIN'],
      user: ENV['SMTP_USER'],
      password: ENV['SMTP_PASSWORD'],
      authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain'),
      enable_starttls_auto: ENV.fetch('SMTP_ENABLE_STARTTLS_AUTO', true).to_s.downcase == 'true'
    )
  end

  def call
    begin
      Net::SMTP.new(@smtp_settings[:server], @smtp_settings[:port]).tap do |smtp|
        smtp.enable_starttls_auto if @smtp_settings[:enable_starttls_auto]
        smtp.start(@smtp_settings[:domain], @smtp_settings[:user], @smtp_settings[:password], @smtp_settings[:authentication])
        smtp.send_message(message, @from, @to)
        smtp.finish
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue Net::SMTPError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def message
    <<~MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE
  end
end