require 'mail'

# Description: Sublayer::Action responsible for parsing incoming emails to extract key information
# and automatically create tasks in tools like Jira or Asana based on email content.
#
# It is initialized with the email content and task management tool configurations.
# It returns the task key/id from the created task.
#
# Example usage: When you want to automate task creation from emails in a project management tool
# such as Jira or Asana.

class EmailParsingTaskCreationAction < Sublayer::Actions::Base
  def initialize(email_content:, task_tool:, tool_config: {})
    @mail = Mail.read_from_string(email_content)
    @task_tool = task_tool
    @tool_config = tool_config
  end

  def call
    extracted_info = parse_email
    create_task(extracted_info)
  rescue StandardError => e
    error_message = "Error processing email for task creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def parse_email
    subject = @mail.subject
    body = @mail.body.decoded

    # Simple placeholder example for extracted information
    {
      title: subject,
      description: body
    }
  end

  def create_task(extracted_info)
    case @task_tool
    when 'jira'
      create_jira_task(extracted_info)
    when 'asana'
      create_asana_task(extracted_info)
    else
      raise StandardError, "Unsupported task management tool: #{@task_tool}"
    end
  end

  def create_jira_task(info)
    # Implement logic to create a task in Jira using info
    # Example: Use Jira client to create issue
    # This is a placeholder logic
    "JIRA-123"
  end

  def create_asana_task(info)
    # Implement logic to create a task in Asana using info
    # Example: Use Asana client to create task
    # This is a placeholder logic
    "ASANA-456"
  end
end
