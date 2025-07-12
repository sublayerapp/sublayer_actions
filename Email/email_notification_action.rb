require 'mail'

# Description: Sublayer::Action responsible for sending an email notification to a specified email address.
# Useful for setting up alerts or updates based on Sublayer processes.
#
# It is initialized with to_email, subject, and body.
# It returns a confirmation message indicating the email was sent successfully.
#
# Example usage: When you want to send an email notification based on AI-driven workflow results.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(to_email:, subject:, body:)
    @to_email = to_email
    @subject = subject
    @body = body
  end

  def call
    mail = Mail.new do
      from     ENV['EMAIL_FROM_ADDRESS']
      to       @to_email
      subject  @subject
      body     @body
    end

    begin
      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_email}")
      "Email to #{@to_email} sent successfully."
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
