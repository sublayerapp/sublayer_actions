# Description: This Sublayer::Action is used to get the name of an Asana task.
#
# It is initialized with a task_gid and returns the name of the task.
#
# Example usage: If you have an AI agent monitoring asana tasks and performing actions based on user comments,
# you can use this action to get the task name to use in a Sublayer::Generator for augmenting the prompt

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
