require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for retrieving the latest email
# from a specified Gmail account.
# Useful for AI agents that need to react to incoming emails.

class GmailGetLatestEmailAction < Sublayer::Actions::Base
  def initialize(user_id: 'me')
    @user_id = user_id
    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = Google::Auth.get_application_default(scope: 'https://www.googleapis.com/auth/gmail.readonly')
  end

  def call
    begin
      # Fetch the latest email (first result from the list)
      response = @gmail.list_user_messages(@user_id, max_results: 1)
      message = response.messages.first

      return nil unless message

      # Retrieve the full message details
      full_message = @gmail.get_user_message(@user_id, message.id)

      # Extract subject and body
      subject = full_message.payload.headers.find { |h| h.name == 'Subject' }&.value
      body = decode_body(full_message.payload)

      { subject: subject, body: body }
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error fetching latest email: #{e.message}")
      raise e
    end
  end

  private

  def decode_body(part)
    if part.parts # Check for multipart emails
      part.parts.map { |p| decode_body(p) }.join
    elsif part.body.data
      Base64.urlsafe_decode64(part.body.data.to_s)
    else
      '' # Handle cases where body is empty or not present
    end
  end
end