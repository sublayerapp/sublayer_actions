class AsanaGetTaskNameAction < AsanaBase
  def initialize(task_gid:, **kwargs)
    super(**kwargs)
    @task_gid = task_gid
  end

  def call
    task = @client.tasks.get_task(task_gid: @task_gid)
    task.name
  end
end
