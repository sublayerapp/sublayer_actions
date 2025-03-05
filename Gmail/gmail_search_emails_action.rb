require 'google/apis/gmail_v1'

# Description: This action searches for emails in a given Gmail mailbox based on query parameters like sender, recipient, date, keywords, and returns a structured list of matching emails with relevant info like sender, subject, date, snippet, etc.

class GmailSearchEmailsAction < Sublayer::Actions::Base
  def initialize(query:, user_id: 'me', max_results: 10)
    @query = query
    @user_id = user_id
    @max_results = max_results
    @client = Google::Apis::GmailV1::GmailService.new
    @client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.readonly'])
  end

  def call
    begin
      response = @client.list_user_messages(@user_id, q: @query, max_results: @max_results)

      emails = response.messages.map do |message|
        message_data = @client.get_user_message(@user_id, message.id)
        {
          id: message_data.id,
          sender: message_data.payload.headers.find { |h| h.name == 'From' }&.value,
          subject: message_data.payload.headers.find { |h| h.name == 'Subject' }&.value,
          date: message_data.payload.headers.find { |h| h.name == 'Date' }&.value,
          snippet: message_data.snippet
        }
      end

      Sublayer.configuration.logger.log(:info, "Found #{emails.count} emails matching the query: #{@query}")

      emails
    rescue Google::Apis::ClientError => e
      Sublayer.configuration.logger.log(:error, "Error searching emails: #{e.message}")
      raise e
    end
  end
end