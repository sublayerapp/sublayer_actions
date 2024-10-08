require "google/apis/gmail_v1"

# Description: Sublayer::Action responsible for sending an email using the Gmail API.
#
# It is initialized with a to, from, subject, and body.
# It returns the message ID to confirm the email was sent successfully.
#
# Example usage: When you want to send an email from an AI process.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, body:)
    @to = to
    @from = from
    @subject = subject
    @body = body

    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = "Sublayer"
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: "https://www.googleapis.com/auth/gmail.send",
      path: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
    )
  end

  def call
    message = Mail.new do
      to @to
      from @from
      subject @subject
      html_part do
        content_type 'text/html; charset=UTF-8'
        body @body
      end
    end

    begin
      @service.send_user_message("me", upload_source: StringIO.new(message.to_s), raw: true)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue Google::Apis::ServerError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end