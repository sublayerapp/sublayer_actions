# Description: Sublayer::Actions used to get the description of an Asana task.
#
# It is initialized with a task_gid and returns the description (called notes in Asana) of the task.
#
# Example usage: We've used the description of an Asana task as the base content for a prompt
# so if you have a workflow where you monitor Asana tasks, you can use this to get the description for sending in to a Sublayer::Generator

class AsanaGetTaskDescriptionAction < AsanaBase
  def initialize(task_gid:, **kwargs)
    super(**kwargs)
    @task_gid = task_gid
  end

  def call
    task = @client.tasks.get_task(task_gid: @task_gid)
    task.notes
  end
end
