# Description: Sublayer::Action responsible for sending an email using a specified provider like Gmail or Outlook.
# This action can be utilized for sending alerts or notifications from AI-driven processes.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with smtp_settings, email details such as from, to, subject, and body.
# It returns true if the email was sent successfully.
#
# Example usage: When you want to send an email notification or alert from an AI process.

require 'mail'

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, from:, to:, subject:, body:)
    @smtp_settings = smtp_settings
    @from = from
    @to = to
    @subject = subject
    @body = body
  end

  def call
    setup_smtp
    send_email
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def setup_smtp
    Mail.defaults do
      delivery_method :smtp, @smtp_settings
    end
  end

  def send_email
    mail = Mail.new do
      from    @from
      to      @to
      subject @subject
      body    @body
    end

    mail.deliver!
    Sublayer.configuration.logger.log(:info, "Email sent successfully from #{@from} to #{@to}")
    true
  end
end