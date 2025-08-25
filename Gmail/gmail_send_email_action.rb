require 'gmail'
require 'mail'

# Description: Sublayer::Action responsible for sending emails through Gmail.
# This action enables AI agents to send automated email updates, reports, or notifications
# through Gmail using the gmail gem.
#
# Requires: 'gmail' gem
# $ gem install gmail
# Or add `gem 'gmail'` to your Gemfile
#
# It is initialized with email details including recipients, subject, body, and optional attachments.
# It returns true on successful email delivery.
#
# Example usage: When you want an AI agent to send automated email updates or reports
# based on its processing results.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, attachments: [], from: nil)
    @to = to
    @subject = subject
    @body = body
    @attachments = attachments
    @from = from || ENV['GMAIL_USER']
    @password = ENV['GMAIL_PASSWORD']
  end

  def call
    begin
      validate_credentials!
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      @gmail&.logout
    end
  end

  private

  def validate_credentials!
    raise StandardError, 'Gmail credentials not configured' if @from.nil? || @password.nil?
  end

  def send_email
    @gmail = Gmail.connect(@from, @password)
    
    @gmail.deliver do
      to @to
      subject @subject
      text_part do
        body @body
      end

      @attachments.each do |attachment|
        add_file attachment
      end
    end
  end
end