require 'mail'

# Description: Sublayer::Action responsible for sending an email with customizable content and attachments.
# This action is intended to be used for notifications, alerts, or sequential data sharing in workflows needing email communication.
#
# It is initialized with from, to, subject, body and optional attachments.
# It returns a confirmation message upon successful sending.
#
# Example usage: When you want to send detailed logs or alerts from an AI process to someone's email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(from:, to:, subject:, body:, attachments: [])
    @from = from
    @to = to
    @subject = subject
    @body = body
    @attachments = attachments
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to \\#{@to}")
      "Email sent successfully"
    rescue StandardError => e
      error_message = "Error sending email: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    mail = Mail.new do
      from    @from
      to      @to
      subject @subject
      body    @body
    end
    
    @attachments.each do |attachment|
      mail.add_file(attachment)
    end

    mail.deliver!
  end
end