require 'mail'

# Description: Sublayer::Action responsible for compiling a daily or weekly digest of updates from systems like Asana, Jira, and GitHub, and sending them via email.
# This is useful for keeping stakeholders informed and aligned with recent developments and changes.
#
# Example usage: Schedule this action to run daily or weekly to keep the team updated with the latest project status in their email.

class EmailDigestCompilationAction < Sublayer::Actions::Base
  def initialize(email_recipients:, frequency: 'daily', **kwargs)
    super(**kwargs)
    @frequency = frequency
    @recipients = email_recipients
    @subject = "#{frequency.capitalize} Digest of Project Updates"
    @updates = [] # This will be populated with updates from various sources
  end

  def call
    begin
      compile_updates
      send_email
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error in compiling or sending digest email: #{e.message}")
      raise e
    end
  end

  private

  def compile_updates
    # Logic to pull updates from Asana, Jira, GitHub, etc. This is a placeholder for the actual update compilation logic.
    @updates << "Asana: Task X was completed"
    @updates << "Jira: Issue Y was resolved"
    @updates << "GitHub: PR #123 was merged"
    Sublayer.configuration.logger.log(:info, "Compiled updates from integrated platforms.")
  end

  def send_email
    Mail.defaults do
      delivery_method :smtp, address: "smtp.example.com", port: 587, user_name: ENV['EMAIL_USER'], password: ENV['EMAIL_PASSWORD'], authentication: :plain, enable_starttls_auto: true
    end

    mail = Mail.new do
      from    ENV['EMAIL_FROM']
      to      @recipients.join(", ")
      subject @subject
      body    format_updates_body
    end

    mail.deliver!
    Sublayer.configuration.logger.log(:info, "Digest email sent successfully to: #{@recipients.join(', ')}")
  end

  def format_updates_body
    "Hello Team,\n\nHere are your #{@frequency} updates:\n\n" + @updates.join("\n") + "\n\nBest Regards,\nYour Automated Digest Bot"
  end
end
