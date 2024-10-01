# Description: Sublayer::Action responsible for creating a task in Asana.
# It inherits from AsanaBase which handles authentication
#
# It is initialized with a project_id, name, description, and attachment, it returns the task.gid to verify it was created.
#
# Example usage: When you have generated a list of tasks from an LLM and want to add them to
# an Asana project for a human or an AI agent to work on

class AsanaCreateTaskAction < AsanaBase
  def initialize(project_id:, name:, description: nil, attachment: nil, **kwargs)
    super(**kwargs)
    @project_id = project_id
    @name = name
    @description = description
    @attachment = attachment
  end

  def call
    task = @client.tasks.create_task(
      projects: [@project_id],
      name: @name,
      notes: @description,
      approval_status: "pending",
      resource_subtype: "approval"
    )

    task.gid
  end
end
