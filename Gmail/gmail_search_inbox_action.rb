require "google/apis/gmail_v1"

# Description: Sublayer::Action for searching a Gmail inbox based on specified criteria.
#
# It is initialized with a query string and optional parameters for filtering results.
# It returns an array of matching email threads, including subject, sender, and date.
#
# Example usage: When you want to find specific emails in a Gmail inbox as part of an AI workflow.

class GmailSearchInboxAction < Sublayer::Actions::Base
  def initialize(query, options: {})
    @query = query
    @options = options
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = "Sublayer App"
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: "https://www.googleapis.com/auth/gmail.readonly",
      path: ENV["GOOGLE_APPLICATION_CREDENTIALS"]
    )
  end

  def call
    begin
      response = @service.list_user_messages("me", q: @query, **@options)
      threads = response.messages || []
      
      threads.map do |thread|
        message = @service.get_user_message("me", thread.id)
        {
          id: thread.id,
          subject: message.payload.headers.find { |h| h.name == "Subject" }&.value,
          sender: message.payload.headers.find { |h| h.name == "From" }&.value,
          date: Time.at(message.internal_date.to_i / 1000).utc
        }
      end
    rescue Google::Apis::ClientError => e
      error_message = "Error searching Gmail inbox: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end