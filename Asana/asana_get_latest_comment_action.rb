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
