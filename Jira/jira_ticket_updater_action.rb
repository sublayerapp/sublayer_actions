# Description: Updates the status or details of a specified Jira ticket,
# keeping project management tools in sync with automation workflows.
#
# It is initialized with a ticket_id, status, and details to update the Jira ticket accordingly.
#
# Example usage: Automate updating the ticket status when a related GitHub PR is merged,
# or when a task in Asana is completed.

require 'jira-ruby'

class JiraTicketUpdaterAction < Sublayer::Actions::Base
  def initialize(site:, context_path:, username:, password:, ticket_id:, status: nil, details: nil)
    @options = {
      site: site,
      context_path: context_path,
      auth_type: :basic,
      username: username,
      password: password
    }
    @ticket_id = ticket_id
    @status = status
    @details = details
    @client = JIRA::Client.new(@options)
  end

  def call
    begin
      issue = @client.Issue.find(@ticket_id)
      update_issue(issue)
    rescue JIRA::HTTPError => e
      log_error("Failed to update Jira ticket: ", e)
    end
  end

  private

  def update_issue(issue)
    fields = {}
    fields['status'] = {'name' => @status} if @status
    fields['description'] = @details if @details
    issue.save({ 'fields' => fields })
    log_info("Successfully updated Jira ticket ", @ticket_id)
  end

  def log_error(message, exception)
    # Here you would integrate with whatever logging framework you're using
    puts "ERROR: "+ message + exception.message
  end

  def log_info(message, ticket_id)
    # Here you would integrate with whatever logging framework you're using
    puts "INFO: "+ message + ticket_id
  end
end