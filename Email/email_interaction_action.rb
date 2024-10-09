require 'mail'

# Description: Sublayer::Action responsible for interacting with email accounts.
# It allows AI agents to send, read, and manage emails, enabling automation of email-based workflows.
#
# Example usage: When you need an AI agent to automatically respond to emails,
# forward important messages, or manage email subscriptions.

class EmailInteractionAction < Sublayer::Actions::Base
  def initialize(action:, **kwargs)
    @action = action
    @options = kwargs

    # Email configuration (replace with your credentials)
    @smtp_server = ENV['SMTP_SERVER']
    @smtp_port = ENV['SMTP_PORT']
    @smtp_user = ENV['SMTP_USER']
    @smtp_password = ENV['SMTP_PASSWORD']
  end

  def call
    case @action
    when :send_email
      send_email
    when :read_email
      read_email
    else
      raise ArgumentError, "Invalid action: #{@action}"
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error in EmailInteractionAction: #{e.message}")
    raise e
  end

  private

  def send_email
    mail = Mail.new do
      from @options[:from]
      to @options[:to]
      subject @options[:subject]
      body @options[:body]
    end

    mail.delivery_method :smtp, address: @smtp_server, port: @smtp_port, user_name: @smtp_user, password: @smtp_password

    mail.deliver

    Sublayer.configuration.logger.log(:info, "Email sent successfully to: #{@options[:to]}")
  end

  def read_email
    # Implement email reading logic here
    raise NotImplementedError, 'Email reading functionality is not yet implemented.'
  end
end