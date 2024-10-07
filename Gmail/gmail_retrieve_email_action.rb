require "google/apis/gmail_v1"

# Description: Sublayer::Action that retrieves emails from a Gmail account.
#
# It can be used to:
# - Monitor a specific mailbox for incoming emails.
# - Extract information from emails to use in Sublayer::Generators.
# - Trigger actions based on email content.
#
# Example usage:
# - Retrieve the latest email received in a specific Gmail mailbox and extract data from it
# - Monitor a support inbox and generate a summary of common issues using an LLM

class GmailRetrieveEmailAction < Sublayer::Actions::Base
  def initialize(query: "in:inbox is:unread", max_results: 1)
    @query = query
    @max_results = max_results
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = "Sublayer App"
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
      path: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
    )
  end

  def call
    begin
      response = @service.list_user_messages("me", q: @query, max_results: @max_results)

      if response.messages.present?
        response.messages.map do |message|
          @service.get_user_message("me", message.id)
        end
      else
        Sublayer.configuration.logger.log(:info, "No emails found matching the query: #{@query}")
        []
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error retrieving emails from Gmail: #{e.message}")
      raise e
    end
  end
end