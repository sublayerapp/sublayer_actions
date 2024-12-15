class EmailQueryInboxAction < Sublayer::Actions::Base
  require 'imap'
  require 'mail'

  # Description: Sublayer::Action responsible for querying a given email inbox
  # for specific emails based on criteria like sender, subject, or date.
  # It would then extract data like the email body and attachments.

  def initialize(server:, port:, username:, password:, mailbox: 'INBOX', search_criteria: {})
    @server = server
    @port = port
    @username = username
    @password = password
    @mailbox = mailbox
    @search_criteria = search_criteria
  end

  def call
    begin
      imap = IMAP::connect({ host: @server, port: @port, ssl: true })
      imap.login(@username, @password)
      imap.select(@mailbox)

      results = []

      imap.search(@search_criteria.map { |k, v| [k.to_s.upcase, v] }).each do |message_id|
        envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
        body = imap.fetch(message_id, "BODY[TEXT]")[0].attr["BODY[TEXT]"]
        attachments = []


        results << { subject: envelope.subject, from: envelope.from, body: body, attachments: attachments }
      end

      imap.logout
      imap.disconnect

      Sublayer.configuration.logger.log(:info, "Successfully queried email inbox and retrieved #{results.count} emails.")
      results
    rescue Net::IMAP::Error => e
      error_message = "Error querying email inbox: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end