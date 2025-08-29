# Description: Sublayer::Action responsible for sending an email using SMTP.
# It can be used for sending notifications, reports, or other automated communications.
#
# Example usage: When you want to send a notification or update from an AI process.

require 'net/smtp'
require 'mail'

class SendEmailAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, body:, smtp_server:, smtp_port:, username:, password:)
    @to = to
    @from = from
    @subject = subject
    @body = body
    @smtp_server = smtp_server
    @smtp_port = smtp_port
    @username = username
    @password = password
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true # Indicate success
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
      false #Indicate failure
    end
  end

  private

  def send_email
    mail = Mail.new do
      to      @to
      from    @from
      subject @subject
      body    @body
    end

    mail.delivery_method(:smtp, {
      :address              => @smtp_server,
      :port                 => @smtp_port,
      :domain               => 'localhost', # You might need to change this
      :user_name            => @username,
      :password             => @password,
      :authentication       => 'plain',
      :enable_starttls_auto => true
    })

    mail.deliver!
  end
end