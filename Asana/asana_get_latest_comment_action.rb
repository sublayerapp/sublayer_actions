# Description: Sublayer::Action responsible for getting the latest comment on a task in Asana.
#
# It is initialized with a task_gid and returns the text of the latest comment.
#
# Example usage: If you have an AI agent monitoring asana tasks and performing actions based on user comments,
# you can use this action to get that comment to use in a Sublayer::Generator for augmenting the prompt with human guidance

class AsanaGetLatestCommentAction < AsanaBase
  def initialize(task_gid:, **kwargs)
    super(**kwargs)
    @task_gid = task_gid
  end

  def call
    task = @client.tasks.get_task(task_gid: @task_gid)
    comments = task.stories.select { |story| story.type == "comment" }
    latest_comment = comments.sort_by { |comment| comment.created_at }.last
    latest.comment.text
  end
end
