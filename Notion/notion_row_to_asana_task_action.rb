class NotionRowToAsanaTaskAction < Sublayer::Actions::Base
  def initialize(row:, project_id:, name_property:, description_property: nil, **kwargs)
    super(**kwargs)
    @row = row
    @project_id = project_id
    @name_property = name_property
    @description_property = description_property
    @asana_client = Asana::Client.new do |c|
      c.authentication :access_token, ENV["ASANA_ACCESS_TOKEN"]
    end
  end

  def call
    task_name = @row[:properties][@name_property][:title][0][:plain_text]
    task_description = @row[:properties][@description_property][:rich_text][0][:plain_text] if @description_property

    begin
      task = @asana_client.tasks.create_task(
        projects: [@project_id],
        name: task_name,
        notes: task_description
      )
      logger.info "Created Asana task: #{task.gid}"
      task.gid
    rescue Asana::Errors::APIError => e
      logger.error "Error creating Asana task: #{e.message}"
      raise e
    end
  end
end