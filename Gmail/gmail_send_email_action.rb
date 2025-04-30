require 'googleauth'
require 'gmail'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# Given recipient email addresses, a subject, and a body, it sends an email.
# Returns a confirmation message upon success or an error message if sending fails.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipients:, subject:, body:)
    @recipients = recipients
    @subject = subject
    @body = body

    # Initialize Gmail client
    scopes = ['https://mail.google.com/']
    authorization = Google::Auth.get_application_default(scopes)
    @gmail = Gmail.connect(:xoauth2, authorization.client_id, authorization.client_secret, authorization.refresh_token)
  end

  def call
    begin
      email = @gmail.compose do
        to @recipients
        subject @subject
        body @body
      end
      email.deliver!

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipients}")
      "Email sent successfully"
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    ensure
      @gmail.logout
    end
  end
end