# Description: Sublayer::Action responsible for retrieving the latest email from an inbox.
# It uses the `mail` gem and can filter by sender, subject, etc. Useful for email-based workflows.

# Requires the `mail` gem. Install by running `gem install mail` or add it to your Gemfile
require 'mail'

class GetLatestEmailAction < Sublayer::Actions::Base
  def initialize(imap_settings:, filter_sender: nil, filter_subject: nil)
    @imap_settings = imap_settings
    @filter_sender = filter_sender
    @filter_subject = filter_subject
  end

  def call
    begin
      Mail.defaults do
        retriever_method :imap, @imap_settings
      end

      emails = Mail.find(limit: 1, order: :desc)
      
      emails = filter_emails(emails)
      
      if emails.empty?
        Sublayer.configuration.logger.log(:warn, "No emails found matching filter criteria.")
        return nil
      end

      latest_email = emails[0]
      
      Sublayer.configuration.logger.log(:info, "Successfully retrieved latest email from inbox")
      latest_email
    rescue => e
      error_message = "Error retrieving latest email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private
  
  def filter_emails(emails)
    emails = emails.select { |email| email.from.include?(@filter_sender)} if @filter_sender
    emails = emails.select { |email| email.subject.include?(@filter_subject) } if @filter_subject
    emails
  end
end