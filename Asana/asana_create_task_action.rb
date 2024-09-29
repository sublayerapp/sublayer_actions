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
