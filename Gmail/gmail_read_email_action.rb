require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for reading emails from a specified Gmail account.
# This action uses the Gmail API and is useful for workflows that involve email processing and data extraction.
#
# It is initialized with various optional parameters to filter emails (e.g., from, subject, label).
# It returns an array of email objects, each containing the subject, sender, and body.
#
# Example usage: Use this action in workflows to process incoming emails, trigger actions based on email content, or extract data for AI models.

class GmailReadEmailAction < Sublayer::Actions::Base
  def initialize(from: nil, subject: nil, label: nil, max_results: 10)
    @from = from
    @subject = subject
    @label = label
    @max_results = max_results

    @client = Google::Apis::GmailV1::GmailService.new
    @client.client_options.application_name = 'Sublayer'
    @client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.readonly'])
  end

  def call
    begin
      query = ""
      query += "from:#{@from} " if @from
      query += "subject:#{@subject} " if @subject
      query += "label:#{@label} " if @label

      results = @client.list_user_messages('me', max_results: @max_results, q: query)
      emails = []

      results.messages&.each do |message|
        message_data = @client.get_user_message('me', message.id)

        subject = message_data.payload.headers.find { |h| h.name == 'Subject' }&.value
        from = message_data.payload.headers.find { |h| h.name == 'From' }&.value
        body = decode_body(message_data.payload)

        emails << { subject: subject, from: from, body: body }
      end

      Sublayer.configuration.logger.log(:info, "Successfully retrieved #{emails.count} emails")
      emails
    rescue StandardError => e
      error_message = "Error reading emails: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def decode_body(part)
    if part.parts
      part.parts.map { |p| decode_body(p) }.join
    elsif part.body.data
      Base64.urlsafe_decode64(part.body.data)
    else
      ""
    end
  end
end